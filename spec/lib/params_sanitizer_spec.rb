require 'spec_helper'

describe ParamsSanitizer do
  describe '.sanitize!' do
    it 'sanitizes given hash' do
      params = {
        'name' => "bad encoding\xff",
        'nested' => {
          'a' => "so wrong\xff",
          'nested2' => {
            'a' => "much bad\xff",
            'b' => 'nope'
          },
          'array' => ["in array\xff", 1, 2 ,3]
        }
      }

      ParamsSanitizer.sanitize!(params)

      expect(params).to eq({
        'name' => "bad encoding",
        'nested' => {
          'a' => "so wrong",
          'nested2' => {
            'a' => "much bad",
            'b' => 'nope'
          },
          'array' => ["in array", 1, 2 ,3]
        }
      })
    end
  end

  describe '.sanitize_value' do
    context 'for a string value' do
      let(:value) { "bad string\xff" }
      let(:good_value) { "bad string" }
      it 'returns this string without bad symbols' do
        expect(ParamsSanitizer.sanitize_value(value)).to eq(good_value)
      end
    end

    context 'for non-string value' do
      let(:value) { 3.14 }
      it 'returns given value' do
        expect(ParamsSanitizer.sanitize_value(value)).to eq(value)
      end
    end
  end
end
