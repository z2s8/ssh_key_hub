require 'active_support/core_ext/object'
require_relative 'key_processor'

module SSHKeyHub::Processor
  # SSH public key filter
  class KeysFilter
    @infinity = 1.0 / 0.0
    # @param [Hash] credentials Hash with keys by username with +SortedSet+s
    def initialize(credentials = {})
      @credentials = credentials.deep_dup
    end

    # Add new credentials to the filter
    # @param [Hash] new_creds Hash with keys by username with +SortedSet+s
    def add(new_creds)
      @credentials.merge!(new_creds) { |_, old_val, new_val| old_val + new_val }
    end

    # TODO
    def allow(type, min_bits, max_bits = @infinity)
    end

    # TODO
    def reject(type, min_bits = 0, max_bits)
    end

    # Remove weak keys from credentials
    # Currently: any DSA, RSA below 2048 bits, and EC below 256 bits
    # @return [Hash] credentials Hash with keys by username with +SortedSet+s
    def reject_weak
      @credentials.each do |user, keys|
        keys.delete_if do |key|
          type, bits = SSHKeyHub::Processor::KeyProcessor.new.key_type_and_bits(key)
          puts "testing #{type} with #{bits}"
          case type
          when :DSA
            true
          when :RSA
            bits < 4096
          when :EC
            bits < 256
          else
            true
          end
        end
      end
      @credentials
    end
  end
end
