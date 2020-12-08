# frozen_string_literal: true

require 'securerandom'
require 'async_storage/util/strings'
require 'async_storage/json'

module AsyncStorage
  class Naming
    include Util::Strings

    SET = {
      temp: 't',
      head: 'h',
      body: 'b',
      none: '_null_',
    }.freeze

    attr_reader :class_name, :class_args
    attr_accessor :prefix

    def initialize(klass, *args)
      @class_name = normalize_class(klass.name)
      @class_args = normalize_args(args)
    end

    def temp
      "#{base}:#{SET[:temp]}"
    end

    def head
      "#{base}:#{SET[:head]}"
    end

    def body
      "#{base}:#{SET[:body]}"
    end

    def to_s
      format(
        '#<AsyncStorage::Naming head=%<head>p body=%<body>p>',
        head: head,
        body: body,
      )
    end

    def eql?(other)
      return false unless other.is_a?(self.class)

      [head, body] == [other.head, other.body]
    end
    alias == eql?

    protected

    def base
      [ns, prefix, class_name, class_args].compact.join(':')
    end

    def normalize_class(name)
      if name.nil? || name.empty?
        raise ArgumentError, 'Anonymous class is not allowed'
      end

      underscore(name, ':')
    end

    def normalize_args(args)
      return SET[:none] if args.empty?

      Digest::SHA256.hexdigest(
        AsyncStorage::JSON.dump(args, mode: :compat),
      )
    end

    def ns
      AsyncStorage.config.namespace
    end
  end
end
