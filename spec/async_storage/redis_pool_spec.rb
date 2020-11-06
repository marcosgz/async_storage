# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AsyncStorage::RedisPool do
  describe 'initialize' do
    context 'with Redis object' do
      subject(:pool) { described_class.new(conn) }

      let(:conn) { Redis.new }

      specify do
        result = nil
        expect { result = pool.with {|c| c.ping } }.not_to raise_error
        expect(result).to eq('PONG')
      end

      specify do
        expect(pool.instance_variable_get(:@connection)).to eq(conn)
      end
    end

    context 'with ConnectionPool object' do
      subject(:pool) { described_class.new(conn) }

      let(:conn) do
        require 'connection_pool'
        ConnectionPool.new { Redis.new }
      end

      specify do
        result = nil
        expect { result = pool.with {|c| c.ping } }.not_to raise_error
        expect(result).to eq('PONG')
      end

      specify do
        expect(pool.instance_variable_get(:@connection)).to eq(conn)
      end
    end

    context 'with Hash object' do
      subject(:pool) { described_class.new(conn) }

      let(:conn) { { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379') } }

      specify do
        result = nil
        expect { result = pool.with {|c| c.ping } }.not_to raise_error
        expect(result).to eq('PONG')
      end

      specify do
        expect(pool.instance_variable_get(:@connection)).to be_an_instance_of(::Redis)
      end
    end

    context 'with nil' do
      subject(:pool) { described_class.new(conn) }

      let(:conn) { nil }

      specify do
        result = nil
        expect { result = pool.with {|c| c.ping } }.not_to raise_error
        expect(result).to eq('PONG')
      end

      specify do
        expect(pool.instance_variable_get(:@connection)).to be_an_instance_of(::Redis)
      end
    end
  end
end
