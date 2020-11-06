# frozen_string_literal: true

module AsyncStorage
  module Util
    module Strings
      module_function

      def underscore(string, module_sep = '/')
        string
          .gsub(/::/, module_sep)
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr('-', '_')
          .downcase
      end
    end
  end
end
