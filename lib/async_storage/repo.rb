# frozen_string_literal: true

module AsyncStorage
  class Repo
    def initialize(resolver_class, **options)
      @resolver_class = resolver_class
      @options = options
    end

    # Async get value with a given key
    #
    # @return [Object, NilClass] Return both stale or fresh object. If does not exist async call the retriever and return nil
    def get(*args)
    end

    # Sync get value with a given value
    #
    # @return [Object] Return the result from resolver
    def get!(*args)
    end

    # Expire object the object with a given key. The stale object will not be removed
    #
    # @return [Boolean] True or False according the object existence
    def invalidate(*args)
    end

    # Delete object with a given key.
    #
    # @return [Boolean] True of according to the object existence
    def invalidate!(*args)
    end

    # Invalidate object with the given key and enqueue background job to update with fresh value
    #
    def refresh(*args)
      tap { |this| this.invalidate(*args) }.get(*args)
    end

    # Delete current object from storage and wait to store/retrieve a fresh one
    #
    # @return [Object] Return the result from resolver
    def refresh!(*args)
      tap { |this| this.invalidate!(*args) }.get!(*args)
    end

    # Check if a fresh value exist.
    #
    # @return [Boolean] True or False according the object existence
    def exist?(*args)
    end

    # Check if object with a given key is stale
    #
    # @return [NilClass, Boolean] Return nil if the object does not exist or true/false according to the object freshness state
    def stale?(*args)
    end

    # Check if a fresh object exists into the storage
    #
    # @return [Boolean] true/false according to the object existence and freshness
    def fresh?(*args)
      exist?(*args) && !stale?(*args)
    end
  end
end
