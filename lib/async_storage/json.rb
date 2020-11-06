# frozen_string_literal: true

require 'multi_json'

module AsyncStorage
  module JSON
    module_function

    # Parses JSON data.
    #
    # @param data [String] JSON data
    # @param options [Hash] Options hash for `MultiJson.load`
    # @return [Object] Parsed JSON
    # @raise [MultiJson::ParseError] MultiJson error classes
    def load(data, **options)
      MultiJson.load(data, **options)
    end

    # Generates JSON.
    #
    # @param object [Object] Object to convert to JSON
    # @param options [Hash] Options hash for `MultiJson.dump` and additional options below
    # @return [String] Generated JSON
    # @raise [MultiJson::DecodeError] MultiJson error classes
    def dump(object, **options)
      object = as_json(object)

      MultiJson.dump(object, **options)
    end

    def as_json(value)
      case value
      when Hash
        value.transform_values { |val| as_json(val) }
      when Enumerable
        value.map { |val| as_json(val) }
      else
        value
      end
    end
  end
end
