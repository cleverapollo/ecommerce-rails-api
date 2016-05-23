require 'rails_helper'

RSpec.describe TriggerMailingQueue, :type => :model do

  describe ".validations" do

    it {
      expect{ TriggerMailingQueue.create(user_id: 1, shop_id: 1, triggered_at: DateTime.current, email: 'aaa@aaa.com', trigger_type: 'recently_purchased', recommended_items: ['1','2','3'], trigger_mail_code: '123') }.to change(TriggerMailingQueue, :count).from(0).to(1)
      expect{ TriggerMailingQueue.create(user_id: 1, shop_id: 1, triggered_at: DateTime.current, email: 'aaa@aaa.com', trigger_type: 'recently_purchased', recommended_items: ['1','2','3']) }.to_not change(SubscribeForCategory, :count)
      expect{ TriggerMailingQueue.create(user_id: 1, shop_id: 1, triggered_at: DateTime.current, email: 'aaa@aaa.com', trigger_type: 'recently_purchased', trigger_mail_code: '123' ) }.to_not change(SubscribeForCategory, :count)
      expect{ TriggerMailingQueue.create(user_id: 1, shop_id: 1, triggered_at: DateTime.current, email: 'aaa@aaa.com', recommended_items: ['1','2','3'], trigger_mail_code: '123') }.to_not change(SubscribeForCategory, :count)
      expect{ TriggerMailingQueue.create(user_id: 1, shop_id: 1, triggered_at: DateTime.current, trigger_type: 'recently_purchased', recommended_items: ['1','2','3'], trigger_mail_code: '123') }.to_not change(SubscribeForCategory, :count)
      expect{ TriggerMailingQueue.create(user_id: 1, shop_id: 1, email: 'aaa@aaa.com', trigger_type: 'recently_purchased', recommended_items: ['1','2','3'], trigger_mail_code: '123') }.to_not change(SubscribeForCategory, :count)
      expect{ TriggerMailingQueue.create(user_id: 1, triggered_at: DateTime.current, email: 'aaa@aaa.com', trigger_type: 'recently_purchased', recommended_items: ['1','2','3'], trigger_mail_code: '123') }.to_not change(SubscribeForCategory, :count)
      expect{ TriggerMailingQueue.create(shop_id: 1, triggered_at: DateTime.current, email: 'aaa@aaa.com', trigger_type: 'recently_purchased', recommended_items: ['1','2','3'], trigger_mail_code: '123') }.to_not change(SubscribeForCategory, :count)
    }

  end

end
