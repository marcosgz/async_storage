# frozen_string_literal: true

require 'spec_helper'

module Dummy
  class BaseError < StandardError; end;
  class InheritedError < BaseError; end;
end

RSpec.describe AsyncStorage::CircuitBreaker do
  let(:config) { described_class.new }
  let(:model) do
    Class.new do
      def fail!(err = StandardError)
        raise err
      end

      def ok!(val = :ok)
        val
      end
    end.new
  end

  after do
    reset_config!
  end

  describe '.run' do
    context 'without default exceptions' do
      specify do
        expect(described_class.new(model).run { model.ok! }).to eq(:ok)
        expect(described_class.new(model).run(fallback: :nope) { model.ok! }).to eq(:ok)
      end

      specify do
        expect(described_class.new(model).run { model.fail! }).to eq(nil)
      end

      specify do
        expect(described_class.new(model).run(fallback: :failed) { model.fail! }).to eq(:failed)
      end

      specify do
        expect(described_class.new(model).run(fallback: -> { 1 + 1 }) { model.fail! }).to eq(2)
      end

      specify do
        expect(described_class.new(model).run(fallback: -> { ok!(:great) }) { model.fail! }).to eq(:great)
      end

      specify do
        expect(described_class.new(model).run(fallback: ->(m) { m.ok!(:great) }) { model.fail! }).to eq(:great)
      end

      specify do
        AsyncStorage.config.circuit_breaker = false
        expect{
          described_class.new(model).run(fallback: :err) { model.fail! }
        }.to raise_error(StandardError)
      end
    end

    context 'with list of exceptions' do
      specify do
        expect(described_class.new(model, exceptions: [Dummy::BaseError]).run { model.ok! }).to eq(:ok)
        expect(described_class.new(model, exceptions: [Dummy::BaseError]).run(fallback: :fail) { model.ok! }).to eq(:ok)
      end

      specify do
        expect(described_class.new(model, exceptions: [Dummy::BaseError]).run(fallback: :err) { model.fail!(Dummy::BaseError) }).to eq(:err)
        expect(described_class.new(model, exceptions: [Dummy::BaseError]).run(fallback: :err) { model.fail!(Dummy::InheritedError) }).to eq(:err)
      end

      specify do
        AsyncStorage.config.circuit_breaker = false
        expect{
          described_class.new(model, exceptions: [Dummy::BaseError]).run(fallback: :err) { model.fail!(Dummy::BaseError) }
        }.to raise_error(Dummy::BaseError)

        expect {
          described_class.new(model, exceptions: [Dummy::BaseError]).run(fallback: :err) { model.fail!(Dummy::InheritedError) }
        }.to raise_error(Dummy::InheritedError)
      end

      specify do
        expect{
          described_class.new(model, exceptions: [Dummy::InheritedError]).run(fallback: :err) { model.fail!(Dummy::BaseError) }
        }.to raise_error(Dummy::BaseError)
        expect{
          described_class.new(model, exceptions: [Dummy::BaseError]).run(fallback: :err) { model.fail!(StandardError) }
        }.to raise_error(StandardError)
      end
    end
  end
end
