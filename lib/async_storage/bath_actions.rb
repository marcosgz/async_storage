# frozen_string_literal: true

module AsyncStorage
  module_function

  def flush_all
    keys.inject(0) do |total, (key, cli)|
      total + cli.del(key)
    end
  end

  def keys
    Enumerator.new do |yielder|
      redis_pool.with do |cli|
        cli.keys("#{config.namespace}:*").each { |key| yielder.yield(key, cli) }
      end
    end
  end
end
