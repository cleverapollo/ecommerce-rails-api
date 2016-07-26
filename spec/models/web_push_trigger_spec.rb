require 'rails_helper'

RSpec.describe WebPushTrigger, :type => :model do

  let!(:shop) { create(:shop) }
  let!(:web_push_trigger) { create(:web_push_trigger, shop: shop, subject: 'Hello', message: 'Sale out') }

  it 'has a valid factory' do
    expect(web_push_trigger).to be_valid
  end

end
