module SSHKeyHub::Exporter
  # Simple key exporter with home directory like subfolders
  class AuthorizedKeysUsers
    def initialize
      @credentials = {}
    end

    def add(new_creds)
      @credentials.merge!(new_creds) { |_, old_val, new_val| old_val + new_val }
    end

    def export(dir_name="home")
      Dir.mkdir dir_name
      Dir.chdir dir_name do
        @credentials.each do |user, keys|
          Dir.mkdir user
          ssh_dir = File.join(user, '.ssh')
          Dir.mkdir ssh_dir
          Dir.chdir ssh_dir do
            File.open('authorized_keys', 'w') do |file|
              keys.each { |key| file.puts key }
            end
          end
        end
      end
    end
  end
end
