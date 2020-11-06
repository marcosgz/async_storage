# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AsyncStorage::Config do
  let(:config) { described_class.new }

  describe 'default values' do
    it { expect(config.redis).to eq(nil) }
    it { expect(config.namespace).to eq('async_storage') }
    it { expect(config.config_path).to eq(nil) }
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
