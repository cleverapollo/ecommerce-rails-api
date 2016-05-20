require 'rails_helper'

RSpec.describe SubscribeForCategory, :type => :model do

  describe ".validations" do

    it {
      expect{ SubscribeForCategory.create(user_id: 1, item_category_id: 1, shop_id: 1, subscribed_at: DateTime.current) }.to change(SubscribeForCategory, :count).from(0).to(1)
      expect{ SubscribeForCategory.create(item_category_id: 1, shop_id: 1, subscribed_at: DateTime.current) }.to_not change(SubscribeForCategory, :count)
      expect{ SubscribeForCategory.create(user_id: 1, shop_id: 1, subscribed_at: DateTime.current) }.to_not change(SubscribeForCategory, :count)
      expect{ SubscribeForCategory.create(user_id: 1, item_category_id: 1, subscribed_at: DateTime.current) }.to_not change(SubscribeForCategory, :count)
      expect{ SubscribeForCategory.create(user_id: 1, item_category_id: 1, shop_id: 1) }.to_not change(SubscribeForCategory, :count)
    }

  end

end
