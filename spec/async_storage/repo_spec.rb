# frozen_string_literal: true

RSpec.describe AsyncStorage::Repo do
  let(:opts) { { expires_in: 10, namespace: ns } }
  let(:ns) { 'test' }

  before do
    AsyncStorage.config.namespace = 'async_storage_test'
    AsyncStorage.flush_all
  end

  after do
    reset_config!
  end

  describe '.get' do
    context 'when synchronous' do
      it 'resolves values and store into redis' do
        allow_any_instance_of(DummyResolver).to receive(:call).and_return(:ok)
        expect(described_class.new(DummyResolver, **opts).get()).to eq('ok')
        10.times { expect(described_class.new(DummyResolver, **opts).get()).to eq('ok') }

        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          expect(r.get(naming.head)).to eq('1')
          expect(r.ttl(naming.head)).to eq(opts[:expires_in])
          expect(r.get(naming.body)).to eq('"ok"')
          expect(r.ttl(naming.body)).to eq(-1)
        end
      end

      it 'resolves nil values and store into redis' do
        allow_any_instance_of(DummyResolver).to receive(:call).and_return(nil)
        expect(described_class.new(DummyResolver, **opts).get()).to eq(nil)
        10.times { expect(described_class.new(DummyResolver, **opts).get()).to eq(nil) }

        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          expect(r.get(naming.head)).to eq('1')
          expect(r.ttl(naming.head)).to eq(opts[:expires_in])
          expect(r.get(naming.body)).to eq('null')
          expect(r.ttl(naming.body)).to eq(-1)
        end
      end

      it 'retrieves the stale content when control key have the :executed value' do
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, '1')
          r.set(naming.body, '{"state":"executed"}')
        end
        expect(described_class.new(DummyResolver, **opts).get()).to eq({'state' => 'executed'})
      end

      it 'retrieves the stale content when control key have the :enqueued value' do
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, '0')
          r.set(naming.body, '{"state":"enqueued"}')
        end
        expect(described_class.new(DummyResolver, **opts).get()).to eq({'state' => 'enqueued'})
      end

      it 'returns nil when the value for the executed key does not exit' do
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, '1')
          r.del(naming.body)
        end
        expect(described_class.new(DummyResolver, **opts).get()).to eq(nil)
      end

      it 'returns nil when the value for the enqueued key does not exit' do
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, '0')
          r.del(naming.body)
        end
        expect(described_class.new(DummyResolver, **opts).get()).to eq(nil)
      end

      it 'raises an error with an unknown value for head' do
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, 'nope')
        end
        expect { described_class.new(DummyResolver, **opts).get() }.to raise_error(
          AsyncStorage::Error, %[the key #{naming.head} have an invalid value. Only "1" or "0" values are expected. And we got "nope"]
        )
      end
    end
  end

  describe '.get!' do
    context 'when synchronous' do
      it 'resolves values and store into redis' do
        allow_any_instance_of(DummyResolver).to receive(:call).and_return(['ok'])
        expect(described_class.new(DummyResolver, **opts).get!()).to eq(['ok'])
        10.times { expect(described_class.new(DummyResolver, **opts).get!()).to eq(['ok']) }

        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          expect(r.get(naming.head)).to eq('1')
          expect(r.ttl(naming.head)).to eq(opts[:expires_in])
          expect(r.get(naming.body)).to eq('["ok"]')
          expect(r.ttl(naming.body)).to eq(-1)
        end
      end

      it 'resolves nil values and store into redis' do
        allow_any_instance_of(DummyResolver).to receive(:call).and_return(nil)
        expect(described_class.new(DummyResolver, **opts).get!()).to eq(nil)
        10.times { expect(described_class.new(DummyResolver, **opts).get!()).to eq(nil) }

        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          expect(r.get(naming.head)).to eq('1')
          expect(r.ttl(naming.head)).to eq(opts[:expires_in])
          expect(r.get(naming.body)).to eq('null')
          expect(r.ttl(naming.body)).to eq(-1)
        end
      end

      it 'retrieves the stale content when control key have the :executed value' do
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, '1')
          r.set(naming.body, '{"state":"executed"}')
        end
        expect(described_class.new(DummyResolver, **opts).get!()).to eq({'state' => 'executed'})
      end

      it 'retrieves the stale content when control key have the :executed value and the value is null' do
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, '1')
          r.set(naming.body, 'null')
        end
        expect(described_class.new(DummyResolver, **opts).get!()).to eq(nil)
      end

      it 'ignores the stale content when control key have the :enqueued value' do
        allow_any_instance_of(DummyResolver).to receive(:call).and_return({'state' => 'executed'})
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, '0')
          r.set(naming.body, '{"state":"enqueued"}')
        end
        expect(described_class.new(DummyResolver, **opts).get!()).to eq({'state' => 'executed'})
      end

      it 'ignores the stale content when control key does not exist' do
        allow_any_instance_of(DummyResolver).to receive(:call).and_return({'state' => 'executed'})
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.del(naming.head)
          r.set(naming.body, '{"state":"missing"}')
        end
        expect(described_class.new(DummyResolver, **opts).get!()).to eq({'state' => 'executed'})
      end

      it 'resolves fresh data when the control key does not exit' do
        allow_any_instance_of(DummyResolver).to receive(:call).and_return({'state' => 'fresh'})
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, '1')
          r.del(naming.body)
        end
        expect(described_class.new(DummyResolver, **opts).get!()).to eq('state' => 'fresh')
      end

      it 'raises an error with an unknown value for head' do
        naming = AsyncStorage::Naming.new(DummyResolver)
        naming.prefix = ns
        pool do |r|
          r.set(naming.head, 'nope')
        end
        expect { described_class.new(DummyResolver, **opts).get!() }.to raise_error(
          AsyncStorage::Error, %[the key #{naming.head} have an invalid value. Only "1" or "0" values are expected. And we got "nope"]
        )
      end
    end
  end

  describe '.invalidate' do
    it 'removes the control key and return false when it does not exist' do
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.del(naming.head)
        r.set(naming.body, 'null')
      end
      expect(described_class.new(DummyResolver, **opts).invalidate()).to eq(false)
      pool do |r|
        expect(r.ttl(naming.head)).to eq(-2)
        expect(r.exists?(naming.head)).to eq(false)
        expect(r.get(naming.body)).to eq('null')
        expect(r.exists?(naming.body)).to eq(true)
        expect(r.ttl(naming.body)).to eq(-1)
      end
    end

    it 'removes the control key and return true when it does exist' do
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.set(naming.head, '1')
        r.expire(naming.head, opts[:expires_in])
        r.set(naming.body, 'null')
      end
      expect(described_class.new(DummyResolver, **opts).invalidate()).to eq(true)
      pool do |r|
        expect(r.ttl(naming.head)).to eq(-2)
        expect(r.exists?(naming.head)).to eq(false)
        expect(r.get(naming.body)).to eq('null')
        expect(r.exists?(naming.body)).to eq(true)
        expect(r.ttl(naming.body)).to eq(-1)
      end
    end
  end

  describe '.invalidate!' do
    it 'removes the control key and body and return false when it does not exist' do
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.del(naming.head)
        r.del(naming.body)
      end
      expect(described_class.new(DummyResolver, **opts).invalidate!()).to eq(false)
      pool do |r|
        expect(r.ttl(naming.head)).to eq(-2)
        expect(r.exists?(naming.head)).to eq(false)
        expect(r.ttl(naming.body)).to eq(-2)
        expect(r.exists?(naming.body)).to eq(false)
      end
    end

    it 'removes the control key and return true when it does exist' do
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.set(naming.head, '1')
        r.expire(naming.head, opts[:expires_in])
        r.set(naming.body, 'null')
      end
      expect(described_class.new(DummyResolver, **opts).invalidate!()).to eq(true)
      pool do |r|
        expect(r.ttl(naming.head)).to eq(-2)
        expect(r.exists?(naming.head)).to eq(false)
        expect(r.ttl(naming.body)).to eq(-2)
        expect(r.exists?(naming.body)).to eq(false)
      end
    end
  end

  describe '.refresh' do
    it 'invalidates the content and return stale value' do
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.set(naming.head, '1')
        r.expire(naming.head, opts[:expires_in])
        r.set(naming.body, '"stale"')
      end
      expect(described_class.new(DummyResolver, **opts).refresh()).to eq("stale")
      pool do |r|
        expect(r.ttl(naming.head)).to eq(-2)
        expect(r.exists?(naming.head)).to eq(false)
        expect(r.get(naming.body)).to eq('"stale"')
        expect(r.exists?(naming.body)).to eq(true)
        expect(r.ttl(naming.body)).to eq(-1)
      end
    end
  end

  describe '.refresh!' do
    it 'invalidates the content and return fresh value' do
      allow_any_instance_of(DummyResolver).to receive(:call).and_return(:fresh)
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.set(naming.head, '1')
        r.expire(naming.head, opts[:expires_in])
        r.set(naming.body, '"stale"')
      end
      expect(described_class.new(DummyResolver, **opts).refresh!()).to eq("fresh")
      pool do |r|
        expect(r.ttl(naming.head)).to eq(opts[:expires_in])
        expect(r.exists?(naming.head)).to eq(true)
        expect(r.get(naming.body)).to eq('"fresh"')
        expect(r.exists?(naming.body)).to eq(true)
        expect(r.ttl(naming.body)).to eq(-1)
      end
    end
  end

  describe '.exist?' do
    specify do
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.set(naming.head, '1')
        r.set(naming.body, '1')
      end
      expect(described_class.new(DummyResolver, **opts).exist?()).to eq(true)
    end

    specify do
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.del(naming.head)
        r.set(naming.body, '1')
      end
      expect(described_class.new(DummyResolver, **opts).exist?()).to eq(false)
    end

    specify do
      naming = AsyncStorage::Naming.new(DummyResolver)
      naming.prefix = ns
      pool do |r|
        r.set(naming.head, '1')
        r.del(naming.body)
      end
      expect(described_class.new(DummyResolver, **opts).exist?()).to eq(false)
    end
  end

  describe '.stale?' do
    specify do
      repo = described_class.new(DummyResolver, **opts)
      repo.get(1) # Add to cache
      expect(repo.stale?(1)).to eq(false)
      repo.invalidate()
      expect(repo.stale?(1)).to eq(false)
      repo.invalidate(1)
      expect(repo.stale?(1)).to eq(true)
    end
  end

  describe '.fresh?' do
    specify do
      repo = described_class.new(DummyResolver, **opts)
      expect(repo.fresh?(1)).to eq(false)
      repo.get(1) # Add to cache
      expect(repo.fresh?(1)).to eq(true)
      expect(repo.fresh?).to eq(false)
      repo.invalidate(1)
      expect(repo.fresh?(1)).to eq(false)
    end
  end

  def pool
    AsyncStorage.redis_pool.with { |c| yield c }
  end
end
