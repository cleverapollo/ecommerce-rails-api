require 'rails_helper'
require 'sales_rate_calс'

describe SalesRateCalc do
  describe '#perform' do
    let!(:shop) { create(:shop) }
    let!(:positive_items) do
      items = []
      5.times do |i|
        items[i] = create(:item, shop: shop, price: rand(10000))
        5.times { create(:action, shop: shop, user: create(:user),item: items[i],
                         timestamp: 1.day.ago.to_i, purchase_count: rand(20)) }
      end
      items
    end

    let!(:bad_item) do
      item = create(:item, shop: shop, price: 100, sr:0.1)
      5.times { create(:action, shop: shop, user: create(:user),item: item,
                       timestamp: 6.months.ago.to_i, purchase_count: rand(20)) }
      item
    end

    subject { SalesRateCalc.perform }

    it 'calculate SR for all items in shop' do
      subject
      positive_items.each do |created_item|
        writed_item = shop.items.find(created_item[:id])
        assert(writed_item.sr>0, "SR cannot be zero in positive items")
      end

      assert(shop.items.find(bad_item[:id]).sr==0, 'SR must be 0 on old items')

    end


  end
end
