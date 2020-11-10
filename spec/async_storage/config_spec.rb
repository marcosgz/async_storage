# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AsyncStorage::Config do
  let(:config) { described_class.new }

  describe 'default values' do
    it { expect(config.redis).to eq(nil) }
    it { expect(config.namespace).to eq('async_storage') }
    it { expect(config.config_path).to eq(nil) }
    it { expect(config.expires_in).to eq(nil) }
    it { expect(config.circuit_breaker).to eq(true) }
    it { expect(config.circuit_breaker?).to eq(true) }
  end

  describe '.circuit_breaker=' do
    specify do
      expect(config.circuit_breaker).to eq(true)
      config.circuit_breaker = false
      expect(config.circuit_breaker).to eq(false)
    end

    specify do
      expect(config.circuit_breaker).to eq(true)
      config.circuit_breaker = 'false'
      expect(config.circuit_breaker).to eq(false)
      config.circuit_breaker = 'true'
      expect(config.circuit_breaker).to eq(true)
    end

    specify do
      expect(config.circuit_breaker).to eq(true)
      config.circuit_breaker = '0'
      expect(config.circuit_breaker).to eq(false)
      config.circuit_breaker = '1'
      expect(config.circuit_breaker).to eq(true)
    end

    specify do
      msg = -> (v) { "The value #{v.inspect} for circuit_breaker is not valid. It must be a boolean" }
      expect { config.circuit_breaker = '' }.to raise_error(AsyncStorage::InvalidConfig, msg.(''))
      expect { config.circuit_breaker = 'yes' }.to raise_error(AsyncStorage::InvalidConfig, msg.('yes'))
      expect { config.circuit_breaker = :false }.to raise_error(AsyncStorage::InvalidConfig, msg.(:false))
      expect { config.circuit_breaker = :true }.to raise_error(AsyncStorage::InvalidConfig, msg.(:true))
    end
  end

  describe '.expires_in=' do
    specify do
      expect(config.expires_in).to eq(nil)
      config.expires_in = 10
      expect(config.expires_in).to eq(10)
    end

    specify do
      expect(config.expires_in).to eq(nil)
      config.expires_in = -1
      expect(config.expires_in).to eq(nil)
    end

    specify do
      expect(config.expires_in).to eq(nil)
      config.expires_in = 0
      expect(config.expires_in).to eq(nil)
    end

    specify do
      expect(config.expires_in).to eq(nil)
      config.expires_in = '60'
      expect(config.expires_in).to eq(60)
    end
  end

  describe '.namespace=' do
    specify do
      msg = -> (v) { "The #{v.inspect} for namespace is not valid. It can't be blank" }
      expect { config.namespace = '' }.to raise_error(AsyncStorage::InvalidConfig, msg.(''))
      expect { config.namespace = nil }.to raise_error(AsyncStorage::InvalidConfig, msg.(nil))
      expect { config.namespace = :'' }.to raise_error(AsyncStorage::InvalidConfig, msg.(''))
    end

    specify do
      expect(config.namespace).to eq('async_storage')
      config.namespace = :custom
      expect(config.namespace).to eq('custom')
    end

    specify do
      expect(config.namespace).to eq('async_storage')
      config.namespace = 'custom-ns'
      expect(config.namespace).to eq('custom-ns')
    end

    context 'from YAML configuration' do
      before do
        config.instance_variable_set(:@config_from_yaml, { 'namespace' => 'ns' })
      end

      it 'loads default config from YAML' do
        expect(config.namespace).to eq('ns')
      end

      it 'overwrites the YAML value' do
        expect(config.namespace).to eq('ns')
        config.namespace = 'custom-ns'
        expect(config.namespace).to eq('custom-ns')
      end
    end
  end
end
