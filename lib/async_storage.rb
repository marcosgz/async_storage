# frozen_string_literal: true

require 'async_storage/version'
require 'async_storage/config'
require 'async_storage/redis_pool'
require 'async_storage/json'
require 'async_storage/repo'

module AsyncStorage
  class Error < StandardError; end
  class InvalidConfig < Error; end

  module_function

  def [](klass, **options)
    Repo.new(klass, **options)
  end

  def config
    @config ||= Config.new
  end

  def configure(&block)
    return unless block_given?

    config.instance_eval(&block)
    @redis_pool = nil
    config
  end

  def redis_pool
    @redis_pool ||= RedisPool.new(config.redis)
  end
end
