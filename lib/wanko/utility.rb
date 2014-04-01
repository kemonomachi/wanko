module Wanko

  # Various utility functions.
  module Utility

    # Public: Recursively convert all keys of a Hash using the supplied block.
    # Array values are traversed and each entry is converted. If arg is any
    # other kind of object it is left untouched. If the conversion results in
    # duplicate keys, later keys will overwrite earlier ones.
    #
    # Convenience functions exist for some often used operations, see
    # ::symbolize_keys and ::stringify_keys.
    #
    # arg   - Object to convert.
    # block - Block for converting the keys. Will be called with each key
    # individually. Should return an object that can be used as a hash key.
    #
    # Examples
    #
    #   Utility.convert_keys h, &:to_sym
    #
    #   Utility.convert_keys(h) {|key| key.downcase.squeeze}
    #
    # Returns an object with converted hash keys.
    def self.convert_keys(arg, &block)
      case arg
      when Hash
        arg.each_with_object({}) { |(key, val), memo|
          memo[yield(key)] = convert_keys(val, &block)
        }
      when Array
        arg.map {|val| convert_keys val, &block}
      else
        arg
      end
    end

    # Public: Recursively convert all keys in a Hash to Symbols. Does not check
    # for duplicate keys. See ::convert_keys for more info.
    #
    # hash - Hash to convert. All keys must respond to #to_sym.
    #
    # Returns a structurally identical Hash with keys converted to Symbols.
    def self.symbolize_keys(hash)
      convert_keys hash, &:to_sym
    end

    # Public: Recursively convert all keys in a Hash to Strings. Does not check
    # for duplicate keys. See ::convert_keys for more info.
    #
    # hash - Hash to convert. All keys must respond to #to_s.
    #
    # Returns a structurally identical Hash with keys converted to Strings.
    def self.stringify_keys(hash)
      convert_keys hash, &:to_s
    end
  end
end

