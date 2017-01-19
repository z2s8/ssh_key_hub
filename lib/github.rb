require 'retries'
require 'octokit'

module Provider
  # GitHub SSH public key provider
  class GitHub
    # @param [Hash] options GitHub credentials for Octokit::Client
    # @option options [String] :access_token OAuth2 access token for
    #   authentication
    # @option options [String] :api_endpoint Base URL for API requests.
    #   default: https://api.github.com/
    # @see http://www.rubydoc.info/github/pengwynn/octokit/Octokit/Configurable
    def initialize(options = {})
      default_options = { auto_paginate: true }
      @client = Octokit::Client.new(default_options.merge(options))
    end

    # @param [String] organization GitHub organization
    # @return [Hash] Hash with keys by username with +SortedSet+s
    def keys_for_whole_org(organization)
      keys_for_members(@client.org_members(organization))
    end

    # @param (see #keys_for_whole_org)
    # @param [String] GitHub team
    # @return (see #keys_for_whole_org)
    def keys_for_org_team(organization, team)
      teams = @client.org_teams(organization).select { |t| t.name == team }
      raise 'Incorrect team' unless teams.size == 1
      team_id = teams.first.id
      keys_for_members(@client.team_members(team_id))
    end

    private def keys_for_members(members)
      credentials = {}
      members.each do |member|
        with_retries do
          credentials[member.login] = SortedSet.new @client.user_keys(member.login).map(&:key)
        end
      end
      credentials
    end
  end
end
