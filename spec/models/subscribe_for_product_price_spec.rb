require 'rails_helper'

RSpec.describe SubscribeForProductPrice, :type => :model do

  describe ".validations" do

    it {
      expect{ SubscribeForProductPrice.create(user_id: 1, item_id: 1, shop_id: 1, subscribed_at: DateTime.current, price: 1.0) }.to change(SubscribeForProductPrice, :count).from(0).to(1)
      expect{ SubscribeForProductPrice.create(item_id: 1, shop_id: 1, subscribed_at: DateTime.current, price: 1.0) }.to_not change(SubscribeForProductPrice, :count)
      expect{ SubscribeForProductPrice.create(user_id: 1, shop_id: 1, subscribed_at: DateTime.current, price: 1.0) }.to_not change(SubscribeForProductPrice, :count)
      expect{ SubscribeForProductPrice.create(user_id: 1, item_id: 1, subscribed_at: DateTime.current, price: 1.0) }.to_not change(SubscribeForProductPrice, :count)
      expect{ SubscribeForProductPrice.create(user_id: 1, item_id: 1, shop_id: 1, price: 1.0) }.to_not change(SubscribeForProductPrice, :count)
      expect{ SubscribeForProductPrice.create(user_id: 1, item_id: 1, shop_id: 1, subscribed_at: DateTime.current) }.to_not change(SubscribeForProductPrice, :count)
    }

  end

end
