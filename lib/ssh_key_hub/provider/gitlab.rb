require 'gitlab'
require 'httparty'
require 'retries'

module SSHKeyHub::Provider
  # GitLab SSH public key provider
  class GitLab
    # @param [Hash] options GitLab credentials for Gitlab::Client
    # @option options [String] :private_token OAuth2 access token for
    #   authentication
    # @option options [String] :endpoint Base URL for API requests.
    #   default: https://api.gitlab.com/v3
    def initialize(options = {})
      default_options = { endpoint: ENV['GITLAB_API_ENDPOINT'] || 'https://gitlab.com/api/v3' }
      @client = Gitlab.client(default_options.merge(options))
      current_user = @client.user
      @web_url = current_user.web_url.gsub(current_user.username, '')
      @is_admin = current_user.is_admin
    end

    # @param [String] group GitLab group
    # @return [Hash] Hash with keys by username with +SortedSet+s
    def keys_for_whole_group(group)
      keys_for_members(@client.group_members(group))
    end

    # TODO
    def keys_for_group_project(group, project)
      #
    end

    def keys_for(group, project = nil)
      if project.nil?
        keys_for_whole_group(group)
      else
        keys_for_group_project(group, project)
      end
    end

    # @param [String] user
    # @return [Array] array of keys
    private def keys_for_user(user)
      with_retries do
        if @is_admin
          # get using the api, availabe only to admins currently
          @client.ssh_keys(user).map(&:key)
        else
          # get via the web, from user.keys
          san_pattern = /[^\p{alpha}0-9\.\-]/ # works with international letters too
          resp = HTTParty.get("#{@web_url}/#{user.gsub(san_pattern, '')}.keys")
          raise 'can\'t retrieve key' unless resp.code == 200
          resp.body.split("\n")
        end
      end
    end

    private def keys_for_members(members)
      credentials = {}
      members.each do |member|
        credentials[member.username] = SortedSet.new keys_for_user(member.username)
      end
      credentials
    end
  end
end
