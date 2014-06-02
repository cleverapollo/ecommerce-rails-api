require 'spec_helper'

describe Rees46 do
  describe '.cookie_name' do
    it 'returns a string' do
      expect(Rees46.cookie_name).to be_a(String)
    end
  end

  describe '.base_url' do
    it 'returns a string' do
      expect(Rees46.base_url).to be_a(String)
    end
  end
end
