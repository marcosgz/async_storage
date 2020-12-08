# frozen_string_literal: true

RSpec.describe AsyncStorage::Naming do
  before do
    AsyncStorage.config.namespace = 'ns'
  end

  after { reset_config! }

  specify do
    model = described_class.new(DummyResolver)
    expect(model.head).to eq('ns:dummy_resolver:_null_:h')
    expect(model.body).to eq('ns:dummy_resolver:_null_:b')
    expect(model.temp).to eq('ns:dummy_resolver:_null_:t')
  end

  specify do
    model = described_class.new(DummyResolver, 1)
    digest = Digest::SHA256.hexdigest('[1]')
    expect(model.head).to eq("ns:dummy_resolver:#{digest}:h")
    expect(model.body).to eq("ns:dummy_resolver:#{digest}:b")
    expect(model.temp).to eq("ns:dummy_resolver:#{digest}:t")
  end

  specify do
    model = described_class.new(DummyResolver, [1,2])
    digest = Digest::SHA256.hexdigest('[[1,2]]')
    expect(model.head).to eq("ns:dummy_resolver:#{digest}:h")
    expect(model.body).to eq("ns:dummy_resolver:#{digest}:b")
    expect(model.temp).to eq("ns:dummy_resolver:#{digest}:t")
  end

  specify do
    model = described_class.new(DummyResolver, { one:1 })
    digest = Digest::SHA256.hexdigest('[{"one":1}]')
    expect(model.head).to eq("ns:dummy_resolver:#{digest}:h")
    expect(model.body).to eq("ns:dummy_resolver:#{digest}:b")
    expect(model.temp).to eq("ns:dummy_resolver:#{digest}:t")
  end

  specify do
    model = described_class.new(DummyResolver, { 'one' => 1 })
    model.prefix = 'test'
    digest = Digest::SHA256.hexdigest('[{"one":1}]')
    expect(model.head).to eq("ns:test:dummy_resolver:#{digest}:h")
    expect(model.body).to eq("ns:test:dummy_resolver:#{digest}:b")
    expect(model.temp).to eq("ns:test:dummy_resolver:#{digest}:t")
  end

  specify do
    expect { described_class.new(Class.new) }.to raise_error(ArgumentError, 'Anonymous class is not allowed')
  end

  specify do
    model = described_class.new(AsyncStorage::Naming, 1)
    digest = Digest::SHA256.hexdigest('[1]')
    expect(model.head).to eq("ns:async_storage:naming:#{digest}:h")
    expect(model.body).to eq("ns:async_storage:naming:#{digest}:b")
    expect(model.temp).to eq("ns:async_storage:naming:#{digest}:t")
  end

  describe '.eql?' do
    specify do
      model = described_class.new(DummyResolver, { one:1 })

      expect(model).to eq(
        described_class.new(DummyResolver, 'one' => 1)
      )
      expect(model).not_to eq(
        described_class.new(DummyResolver, 'one' => '1')
      )
    end
  end
end
