require 'rails_helper'

describe SalesRateCalculator do

  describe '.perform' do

    context 'all shops with enough sales' do

      let!(:shop) { create(:shop) }
      10.times do |i|
        let!("user#{i}".to_sym) { create(:user) }
        let!("item#{i}".to_sym) { create(:item, shop: shop) }
      end

      #
      # let!(:item1) { create(:item, shop: shop) }
      # let!(:item2) { create(:item, shop: shop) }
      # let!(:item3) { create(:item, shop: shop) }
      # let!(:item4) { create(:item, shop: shop) }
      # let!(:user1) { create(:user) }
      # let!(:user2) { create(:user) }
      # let!(:pucrhase1) { create(:action, rating: Actions::Purchase::RATING, shop: shop, user: user1, item: item1, timestamp: 1.day.ago) }
      # let!(:purchase2) { create(:action, rating: Actions::Purchase::RATING, shop: shop, user: user1, item: item2, timestamp: 1.days.ago) }
      # let!(:purchase3) { create(:action, rating: Actions::Purchase::RATING, shop: shop, user: user2, item: item2, timestamp: 1.days.ago) }
      # let!(:cart1) { create(:action, rating: Actions::Cart::RATING, shop: shop, user: user1, item: item4, timestamp: 1.days.ago) }

      it 'calculates normal sales rate for all shops' do
        SalesRateCalculator.perform
        # puts item2.reload.sales_rate
        # expect(cart1.reload.rating).to eq(Actions::Cart::RATING)
        # expect(cart2.reload.rating).to eq(Actions::RemoveFromCart::RATING)
      end
    end

    context 'all shops with not enough sales' do
      it 'calculates sales rate for all shops with not enough sales rate' do
        SalesRateCalculator.perform
        # puts item2.reload.sales_rate
        # expect(cart1.reload.rating).to eq(Actions::Cart::RATING)
        # expect(cart2.reload.rating).to eq(Actions::RemoveFromCart::RATING)
      end
    end

  end


  describe '.perform_newbies' do

    context 'new shop with enough sales' do
      it 'calculates sales rate for new shops' do
        SalesRateCalculator.perform_newbies
      end
    end

    context 'new shop with not enough sales' do
      it 'calculates sales rate for new shops with not enough sales data' do
        SalesRateCalculator.perform_newbies
      end
    end

  end


end
