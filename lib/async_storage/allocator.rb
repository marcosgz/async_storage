# frozen_string_literal: true

require 'async_storage/naming'

module AsyncStorage
  class Allocator
    CTRL = {
      enqueued: '0',
      executed: '1',
      missing: nil,
    }.freeze

    extend Forwardable
    def_delegators :@repo, :resolver_class, :expires_in

    attr_reader :naming

    # @param repo [AsyncStorage::Repo] An instance of Repo
    # @param args [Array] An array with arguments to be fowarded to resolver#call
    def initialize(repo, *args)
      @repo = repo
      @args = args
      @naming = AsyncStorage::Naming.new(repo.resolver_class, *args)
      # It's different than the config.namespace.
      # Thinking about a directory structure.. The global namespace would be the root directory.
      # And the namespace under Repo level would be the subdirectory.
      @naming.prefix = repo.namespace if repo.namespace
    end

    # Async get value with a given key
    #
    # @return [Object, NilClass] Return both stale or fresh object. If does not exist async call the retriever and return nil
    def get
      connection do |redis|
        raw_head = redis.get(naming.head)
        case raw_head
        when CTRL[:executed], CTRL[:enqueued]
          read_body(redis) # Try to deliver stale content
        when CTRL[:missing]
          return update!(redis) unless async?

          perform_async(redis) # Enqueue background job to resolve content
          redis.set(naming.head, CTRL[:enqueued])
          read_body(redis) # Try to deliver stale content
        else
          raise AsyncStorage::Error, format('the key %<k>s have an invalid value. Only "1" or "0" values are expected. And we got %<v>p', v: raw_head, k: naming.head)
        end
      end
    end

    # Sync get value with a given value
    #
    # @return [Object] Return the result from resolver
    def get!
      connection do |redis|
        raw_head = redis.get(naming.head)
        case raw_head
        when CTRL[:executed]
          read_body(redis) || begin
            update!(redis) unless redis.exists?(naming.body)
          end
        when CTRL[:missing], CTRL[:enqueued]
          update!(redis)
        else
          raise AsyncStorage::Error, format('the key %<k>s have an invalid value. Only "1" or "0" values are expected. And we got %<v>p', v: raw_head, k: naming.head)
        end
      end
    end

    # Expire object the object with a given key. The stale object will not be removed
    #
    # @return [Boolean] True or False according to the object existence
    def invalidate
      connection do |redis|
        redis.del(naming.head) == 1
      end
    end

    # Delete object with a given key.
    #
    # @return [Boolean] True or False according to the object existence
    def invalidate!
      connection do |redis|
        redis.multi do |cli|
          cli.del(naming.body)
          cli.del(naming.head)
        end.include?(1)
      end
    end

    # Invalidate object with the given key and update content according to the strategy
    #
    # @return [Object, NilClass] Stale object or nil when it does not exist
    def refresh
      value = get(*@args)
      invalidate(*@args)
      value
    end

    # Fetch data from resolver and store it into redis
    #
    # @return [Object] Return the result from resolver
    def refresh!
      connection { |redis| update!(redis) }
    end

    # Check if a fresh value exist.
    #
    # @return [Boolean] True or False according the object existence
    def exist?
      connection { |redis| redis.exists?(naming.head) && redis.exists?(naming.body) }
    end

    # Check if object with a given key is stale
    #
    # @return [NilClass, Boolean] Return nil if the object does not exist or true/false according to the object freshness state
    def stale?
      connection { |redis| redis.exists?(naming.body) && redis.ttl(naming.head) < 0 }
    end

    # Check if a fresh object exists into the storage
    #
    # @return [Boolean] true/false according to the object existence and freshness
    def fresh?
      connection { |redis| redis.exists?(naming.body) && redis.ttl(naming.head) > 0 }
    end

    private

    def async?
      false
    end

    def perform_async(redis)
      # @TODO Enqueue a real background job here. It's only working on sync mode
      # redis.set(name.head, CTRL[:enqueued])
      refresh!
    end

    def update!(redis)
      payload = resolver_class.new.(*@args)

      json = AsyncStorage::JSON.dump(payload, mode: :compat)
      redis.multi do |cli|
        cli.set(naming.body, json)
        cli.set(naming.head, CTRL[:executed])
        cli.expire(naming.head, expires_in) if expires_in
      end
      AsyncStorage::JSON.load(json)
    end

    def read_body(redis)
      raw = redis.get(naming.body)
      return unless raw

      AsyncStorage::JSON.load(raw)
    end

    def connection
      return unless block_given?

      AsyncStorage.redis_pool.with { |redis| yield(redis) }
    end
  end
end
