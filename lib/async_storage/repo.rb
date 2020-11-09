# frozen_string_literal: true

require 'async_storage/naming'

module AsyncStorage
  class Repo
    CTRL = {
      enqueued: '0',
      executed: '1',
      missing: nil,
    }.freeze

    attr_reader :resolver_class

    # @param resolver_class [Class] A class with the call method
    # @param options [Hash] A hash with config
    # @option expires_in [Nil, Integer] Time in seconds
    # @raise [ArgumentError] When the resolver_class does not respond with `call' instance method
    def initialize(resolver_class, **options)
      validate_resolver_class!(resolver_class)
      @resolver_class = resolver_class
      @options = options
    end

    # Store a fresh content into redis. This method is invoked by a background job.
    #
    # @param options [Hash] List of options to be passed along the initializer
    # @option [Class] klass The resolver class
    # @option [Array] args An array with the resolver arguments
    # @return [Hash, NilClass] the result from class resolver
    def self.ack(klass:, args:, **options)
      new(klass, **options).refresh!(*args)
    end

    # Async get value with a given key
    #
    # @return [Object, NilClass] Return both stale or fresh object. If does not exist async call the retriever and return nil
    def get(*args)
      connection(*args) do |redis, naming|
        raw_head = redis.get(naming.head)
        case raw_head
        when CTRL[:executed], CTRL[:enqueued]
          read(redis, naming.body) # Try to deliver stale content
        when CTRL[:missing]
          return update!(redis, naming, *args) unless async?

          perform_async(*args) # Enqueue background job to resolve content
          redis.set(naming.head, CTRL[:enqueued])
          read(redis, naming.body) # Try to deliver stale content
        else
          raise AsyncStorage::Error, format('the key %<k>s have an invalid value. Only "1" or "0" values are expected. And we got %<v>p', v: raw_head, k: naming.head)
        end
      end
    end

    # Sync get value with a given value
    #
    # @return [Object] Return the result from resolver
    def get!(*args)
      connection(*args) do |redis, naming|
        raw_head = redis.get(naming.head)
        case raw_head
        when CTRL[:executed]
          read(redis, naming.body) || begin
            update!(redis, naming, *args) unless redis.exists?(naming.body)
          end
        when CTRL[:missing], CTRL[:enqueued]
          update!(redis, naming, *args)
        else
          raise AsyncStorage::Error, format('the key %<k>s have an invalid value. Only "1" or "0" values are expected. And we got %<v>p', v: raw_head, k: naming.head)
        end
      end
    end

    # Expire object the object with a given key. The stale object will not be removed
    #
    # @return [Boolean] True or False according to the object existence
    def invalidate(*args)
      connection(*args) do |redis, naming|
        redis.del(naming.head) == 1
      end
    end

    # Delete object with a given key.
    #
    # @return [Boolean] True or False according to the object existence
    def invalidate!(*args)
      connection(*args) do |redis, naming|
        redis.multi do |cli|
          cli.del(naming.body)
          cli.del(naming.head)
        end.include?(1)
      end
    end

    # Invalidate object with the given key and update content according to the strategy
    #
    # @return [Object, NilClass] Stale object or nil when it does not exist
    def refresh(*args)
      value = get(*args)
      invalidate(*args)
      value
    end

    # Fetch data from resolver and store it into redis
    #
    # @return [Object] Return the result from resolver
    def refresh!(*args)
      connection(*args) { |redis, naming| update!(redis, naming, *args) }
    end

    # Check if a fresh value exist.
    #
    # @return [Boolean] True or False according the object existence
    def exist?(*args)
      connection(*args) { |redis, naming| redis.exists?(naming.head) && redis.exists?(naming.body) }
    end

    # Check if object with a given key is stale
    #
    # @return [NilClass, Boolean] Return nil if the object does not exist or true/false according to the object freshness state
    def stale?(*args)
      connection(*args) { |redis, naming| redis.exists?(naming.body) && redis.ttl(naming.head) < 0 }
    end

    # Check if a fresh object exists into the storage
    #
    # @return [Boolean] true/false according to the object existence and freshness
    def fresh?(*args)
      connection(*args) { |redis, naming| redis.exists?(naming.body) && redis.ttl(naming.head) > 0 }
    end

    private

    def async?
      false
    end

    def perform_async(*args)
      # @TODO Enqueue a real background job here. It's only working on sync mode
      # redis.set(name.head, CTRL[:enqueued])
      refresh!(*args)
    end

    def update!(redis, naming, *args)
      payload = resolver_class.new.(*args)

      json = AsyncStorage::JSON.dump(payload, mode: :compat)
      naming = build_naming(*args)
      redis.multi do |cli|
        cli.set(naming.body, json)
        cli.set(naming.head, CTRL[:executed])
        cli.expire(naming.head, expires_in) if expires_in
      end
      AsyncStorage::JSON.load(json)
    end

    def read(redis, key)
      return unless key

      raw = redis.get(key)
      return unless raw

      AsyncStorage::JSON.load(raw)
    end

    def expires_in
      @options[:expires_in] || AsyncStorage.config.expires_in
    end

    def connection(*args)
      return unless block_given?

      naming = build_naming(*args)
      AsyncStorage.redis_pool.with { |redis| yield(redis, naming) }
    end

    def build_naming(*args)
      naming = AsyncStorage::Naming.new(resolver_class, *args)
      naming.prefix = @options[:namespace] if @options[:namespace]
      naming
    end

    def validate_resolver_class!(klass)
      unless klass.is_a?(Class)
        raise(ArgumentError, format('%<c>p is not a valid resolver class.', c: klass))
      end

      unless klass.instance_methods.include?(:call)
        raise(ArgumentError, format('%<c>p must have call instance method.', c: klass))
      end

      true
    end
  end
end
