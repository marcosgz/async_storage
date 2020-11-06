# frizen_string_literal: true

require 'redis'
require 'yaml'

module AsyncStorage
  class Config
    class << self
      private

      def attribute_accessor(field, validator: nil, normalizer: nil, default: nil)
        normalizer ||= :"normalize_#{field}"
        validator ||= :"validate_#{field}"

        define_method(field) do
          unless instance_variable_defined?(:"@#{field}")
            fallback = config_from_yaml[field.to_s] || default
            return if fallback.nil?

            send(:"#{field}=", fallback.respond_to?(:call) ? fallback.call : fallback)
          end
          instance_variable_get(:"@#{field}")
        end

        define_method(:"#{field}=") do |value|
          value = send(normalizer, field, value) if respond_to?(normalizer, true)
          send(validator, field, value) if respond_to?(validator, true)

          instance_variable_set(:"@#{field}", value)
        end
      end
    end

    # Path to the YAML file with configs
    attr_accessor :config_path

    # Redis/ConnectionPool instance of a valid list of configs to build a new redis connection
    attribute_accessor :redis, default: nil

    # Namespace used to group group data stored by this package
    attribute_accessor :namespace, default: 'async_storage'

    def config_path=(value)
      @config_from_yaml = nil
      @config_path = value
    end

    private

    def normalize_namespace(_attribute, value)
      return value.to_s if value.is_a?(Symbol)

      value
    end

    def validate_namespace(attribute, value)
      return if value.is_a?(String) && !value.empty?

      raise InvalidConfig, format(
        "The %<value>p for %<attr>s is not valid. It can't be blank",
        value: value,
        attr: attribute,
      )
    end

    def config_from_yaml
      @config_from_yaml ||= begin
        config_path ? YAML.load_file(config_path) : {}
      rescue Errno::ENOENT, Errno::ESRCH
        {}
      end
    end
  end
end
