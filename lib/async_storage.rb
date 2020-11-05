# frozen_string_literal: true

require 'async_storage/version'
require 'async_storage/json'
require 'async_storage/repo'

module AsyncStorage
  class Error < StandardError; end

  def self.[](klass, **options)
    Repo.new(klass, **options)
  end
end
