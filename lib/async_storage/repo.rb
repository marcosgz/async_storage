# frozen_string_literal: true

require 'async_storage/allocator'

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
      alloc(*args).get
    end

    # Sync get value with a given value
    #
    # @return [Object] Return the result from resolver
    def get!(*args)
      alloc(*args).get!
    end

    # Expire object the object with a given key. The stale object will not be removed
    #
    # @return [Boolean] True or False according to the object existence
    def invalidate(*args)
      alloc(*args).invalidate
    end

    # Delete object with a given key.
    #
    # @return [Boolean] True or False according to the object existence
    def invalidate!(*args)
      alloc(*args).invalidate!
    end

    # Invalidate object with the given key and update content according to the strategy
    #
    # @return [Object, NilClass] Stale object or nil when it does not exist
    def refresh(*args)
      alloc(*args).refresh
    end

    # Fetch data from resolver and store it into redis
    #
    # @return [Object] Return the result from resolver
    def refresh!(*args)
      alloc(*args).refresh!
    end

    # Check if a fresh value exist.
    #
    # @return [Boolean] True or False according the object existence
    def exist?(*args)
      alloc(*args).exist?
    end

    # Check if object with a given key is stale
    #
    # @return [NilClass, Boolean] Return nil if the object does not exist or true/false according to the object freshness state
    def stale?(*args)
      alloc(*args).stale?
    end

    # Check if a fresh object exists into the storage
    #
    # @return [Boolean] true/false according to the object existence and freshness
    def fresh?(*args)
      alloc(*args).fresh?
    end

    # Build an Allocator instance
    #
    # @param [*Array] list of parameters to be forwaded to the resolver#call
    def alloc(*args)
      Allocator.new(self, *args)
    end

    def expires_in
      @options[:expires_in] || AsyncStorage.config.expires_in
    end

    def namespace
      @options[:namespace]
    end

    protected

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
