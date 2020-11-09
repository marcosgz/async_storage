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

  describe '.flush_all' do
    let(:pool) { described_class.redis_pool }
    let(:ns) { described_class.config.namespace }

    specify do
      pool.with { |c| c.set("#{ns}:foo", 0) }
      pool.with { |c| c.set("#{ns}:bar", 0) }
      pool.with { |c| c.set("#{ns}1:other", 0) }
      expect(described_class.flush_all).to be >= 2
      pool do |cli|
        expect(cli).not_to be_exists("#{ns}:foo")
        expect(cli).not_to be_exists("#{ns}:bar")
        expect(cli).to be_exists("#{ns}1:other")
        cli.del("#{ns}1:other")
      end
    end
  end

  describe '.keys' do
    let(:pool) { described_class.redis_pool }
    let(:ns) { described_class.config.namespace }

    specify do
      expect(described_class.keys).to be_an_instance_of(Enumerator)
    end

    specify do
      pool.with { |c| c.set("#{ns}:foo", 0) }
      expect(described_class.keys).to include("#{ns}:foo")
      pool.with { |c| c.del("#{ns}:foo") }
      expect(described_class.keys).not_to include("#{ns}:foo")
    end
  end
end
