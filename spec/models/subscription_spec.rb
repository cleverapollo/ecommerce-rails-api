require 'spec_helper'

describe Subscription do
  subject { create(:subscription) }

  describe '#to_json' do
    it 'returns JSON with needed attributes' do
      expect(subject.to_json).to eq("{\"active\":true,\"declined\":false,\"email\":null,\"name\":null}")
    end
  end

  describe '#declined=' do
    it 'deactivates subscription when declined value is true' do
      subject.declined = true
      expect(subject.active).to be_false
    end
  end

  describe '#deactivate!' do
    it 'deactivates subscription' do
      subject.deactivate!
      expect(subject.active).to be_false
    end
  end

  describe '#set_dont_disturb!' do
    it 'sets dont disturb to DONT_DISTURB_DAYS_COUNT from now' do
      Timecop.freeze
      subject.set_dont_disturb!
      expect(subject.dont_disturb_until).to eq(Subscription::DONT_DISTURB_DAYS_COUNT.days.from_now)
    end
  end
end
