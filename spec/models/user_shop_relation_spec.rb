require 'rails_helper'

describe UserShopRelation do
  describe '.with_email' do
    it 'returns only relations with email' do
      shop = create(:shop)
      user1 = create(:user)
      user2 = create(:user)

      u_s_r_1 = create(:user_shop_relation, user: user1, shop: shop, uniqid: '1', email: nil)
      u_s_r_2 = create(:user_shop_relation, user: user2, shop: shop, uniqid: '2', email: 'test@test.te')

      expect(UserShopRelation.with_email.to_a).to match_array([u_s_r_2])
    end
  end
end
