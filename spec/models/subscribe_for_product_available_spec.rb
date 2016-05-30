require 'rails_helper'

RSpec.describe SubscribeForProductAvailable, :type => :model do

  describe ".validations" do

    it {
      expect{ SubscribeForProductAvailable.create(user_id: 1, item_id: 1, shop_id: 1, subscribed_at: DateTime.current) }.to change(SubscribeForProductAvailable, :count).from(0).to(1)
      expect{ SubscribeForProductAvailable.create(item_id: 1, shop_id: 1, subscribed_at: DateTime.current) }.to_not change(SubscribeForProductAvailable, :count)
      expect{ SubscribeForProductAvailable.create(user_id: 1, shop_id: 1, subscribed_at: DateTime.current) }.to_not change(SubscribeForProductAvailable, :count)
      expect{ SubscribeForProductAvailable.create(user_id: 1, item_id: 1, subscribed_at: DateTime.current) }.to_not change(SubscribeForProductAvailable, :count)
      expect{ SubscribeForProductAvailable.create(user_id: 1, item_id: 1, shop_id: 1) }.to_not change(SubscribeForProductAvailable, :count)
    }

  end

end
