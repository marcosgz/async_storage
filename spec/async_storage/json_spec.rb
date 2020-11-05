# frozen_string_literal: true

RSpec.describe AsyncStorage::JSON do
  describe '.dump' do
    specify do
      expected_data = %[{"args":[1,"2"]}]

      expect(described_class.dump('args' => [1, "2"])).to eq(expected_data)
    end
  end

  describe '.load' do
    specify do
      data = <<~STR
      {
        "args": [1, "2"]
      }
      STR
      expect(described_class.load(data)).to eq(
        'args' => [1, "2"],
      )
    end
  end
end
