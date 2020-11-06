# frozen_string_literal: true

RSpec.describe AsyncStorage do
  it 'has a version number' do
    expect(AsyncStorage::VERSION).not_to be nil
  end

  describe '.config class method' do
    it { expect(described_class.config).to be_an_instance_of(AsyncStorage::Config) }
  end

  describe '.redis_pool' do
    it { expect(described_class.redis_pool).to be_an_instance_of(AsyncStorage::RedisPool) }
  end

  describe '.configure' do
    after { reset_config! }

    it 'overwrites default config value' do
      described_class.config.namespace = 'async-store1'

      described_class.configure { |config| config.namespace = 'async-store2' }
      expect(described_class.config.namespace).to eq('async-store2')
    end

    it 'starts a fresh redis pool' do
      pool = described_class.redis_pool
      3.times { expect(described_class.redis_pool).to eql(pool) }
      described_class.configure { |config| config.namespace = 'async-store' }
      expect(described_class.redis_pool).not_to eql(pool)
    end
  end
end
