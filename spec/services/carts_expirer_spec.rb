require 'rails_helper'

describe CartsExpirer do
  describe '.perform!' do
    let!(:shop) { create(:shop) }
    let!(:item1) { create(:item, shop: shop) }
    let!(:item2) { create(:item, shop: shop) }
    let!(:user) { create(:user) }
    let!(:cart1) { create(:action, rating: Actions::Cart::RATING, shop: shop, user: user, item: item1, cart_date: 1.day.ago) }
    let!(:cart2) { create(:action, rating: Actions::Cart::RATING, shop: shop, user: user, item: item2, cart_date: 3.days.ago) }

    it 'expires carts that older than 2 days' do
      CartsExpirer.perform

      expect(cart1.reload.rating).to eq(Actions::Cart::RATING)
      expect(cart2.reload.rating).to eq(Actions::RemoveFromCart::RATING)
    end
  end
end
