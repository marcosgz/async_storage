# frozen_string_literal: true

require 'async_storage/util/strings'

RSpec.describe AsyncStorage::Util::Strings do
  describe '.underscore' do
    it { expect(AsyncStorage::Util::Strings.underscore('ClassName')).to eq('class_name') }
    it { expect(AsyncStorage::Util::Strings.underscore('Namespace::ClassName')).to eq('namespace/class_name') }
    it { expect(AsyncStorage::Util::Strings.underscore('::Namespace::ClassName')).to eq('namespace/class_name') }
    it { expect(AsyncStorage::Util::Strings.underscore('Namespace::ClassName', '.')).to eq('namespace.class_name') }
  end
end
