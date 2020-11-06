# frozen_string_literal: true

require 'redis'
require 'forwardable'

module AsyncStorage
  class RedisPool
    extend Forwardable
    def_delegator :@connection, :with

    module ConnectionPoolLike
      def with
        yield self
      end
    end

    def initialize(connection)
      if connection.respond_to?(:with)
        @connection = connection
      else
        if connection.respond_to?(:client)
          @connection = connection
        else
          @connection = ::Redis.new(*[connection].compact)
        end
        @connection.extend(ConnectionPoolLike)
      end
    end
  end
end
