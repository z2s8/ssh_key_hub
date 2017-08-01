require_relative 'provider/github'
require_relative 'provider/gitlab'
require_relative 'processor/keys_filter'

class Keys
  def initialize(&block)
    self.evaluate(&block)
    puts "k #{@export}"
  end

  def evaluate(&block)
    @self_before_instance_eval = eval "self", block.binding
    instance_eval &block
  end

  def method_missing(method, *args, &block)
    @self_before_instance_eval.send method, *args, &block
  end

  def export
    @export = true
  end

  def reject_weak
    filter = SSHKeyHub::Processor::KeysFilter.new @credentials
    @credentials = filter.reject_weak
  end

  def add(new_creds)
    @credentials ||= {}
    @credentials.merge!(new_creds) { |_, old_val, new_val| old_val + new_val }
  end

  # access_token, api_endpoint
  def github(org:, team: nil, **kwargs, &block)
    gh = SSHKeyHub::Provider::GitHub.new(kwargs)
    if block_given?
      Class.new(Keys) do
        def initialize(gh, org, team, &block)
          puts 'inner block'
          @credentials = gh.keys_for(org, team)
          @self_before_instance_eval = eval "self", block.binding
          instance_eval &block
          puts @credentials
          puts "endofinner kk #{@export}"
        end
      end.new(gh, org, team, &block)
    else
      add gh.keys_for(org, team)
    end
  end

  def gitlab(group:, project: nil, **kwargs)
    gl = SSHKeyHub::Provider::GitLab.new(kwargs)
    add gl.keys_for(group, project)
  end
end
