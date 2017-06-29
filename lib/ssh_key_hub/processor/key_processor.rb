require 'net/ssh'

module SSHKeyHub::Processor
  # SSH public key analyzer
  class KeyProcessor
    # @param [String] key public key data
    # @param [OpenSSL::PKey] pkey loaded ssh key object (optional)
    # @return [Symbol] key type, currently +:RSA+, +:DSA+, +:EC+, +:UNKNOWN+
    def key_type(key, pkey = nil)
      pkey ||= Net::SSH::KeyFactory.load_data_public_key(key) rescue nil
      return :UNKNOWN if pkey.nil?
      :"#{pkey.class.name.split('::').last}"
    end

    # @param (see #key_type)
    # @return [Integer] key size in bits
    def key_bits(key, pkey = nil)
      pkey ||= Net::SSH::KeyFactory.load_data_public_key(key) rescue nil
      case pkey
      when OpenSSL::PKey::RSA
        return pkey.n.num_bits
      when OpenSSL::PKey::DSA
        return pkey.pub_key.num_bits
      when OpenSSL::PKey::EC
        return pkey.group.degree
      else
        # Currently Ed25519 keys aren't supported by Ruby's OpenSSL library
        puts "[KeyProcessor] Unknown key type for: #{key}"
        return -1
      end
    end

    # @param (see #key_type)
    # @return [Array<Symbol, Integer>] Array of key type and size in bits, eg. +[:RSA, 4096]+
    def key_type_and_bits(key, pkey = nil)
      pkey ||= Net::SSH::KeyFactory.load_data_public_key(key) rescue nil
      [key_type(key, pkey), key_bits(key, pkey)]
    end
  end
end
