require 'rails_helper'

RSpec.describe WebPushTriggerMessage, :type => :model do

  let!(:shop) { create(:shop) }
  let!(:user) { create(:user) }
  let!(:client) { create(:client, :with_email, shop: shop, user: user) }
  let!(:web_push_trigger) { create(:web_push_trigger, shop: shop, subject: 'Hello', message: 'Sale out') }
  let!(:web_push_trigger_message) { create(:web_push_trigger_message, shop: shop, web_push_trigger: web_push_trigger, trigger_data: {sample: true}) }

  it 'has a valid factory' do
    expect(web_push_trigger_message).to be_valid
  end

  describe '#mark_as_clicked!' do
    it 'marks message as clicked' do
      expect{ web_push_trigger_message.mark_as_clicked! }.to change{ web_push_trigger_message.clicked }.from(false).to(true)
    end
  end

  describe '#mark_as_unsubscribed!' do
    subject { web_push_trigger_message.mark_as_unsubscribed! }

    it 'marks mailing as unsubscribed' do
      expect{ subject }.to change{ web_push_trigger_message.unsubscribed }.from(false).to(true)
    end

  end
  
end
