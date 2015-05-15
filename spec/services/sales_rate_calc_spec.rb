require 'rails_helper'
require 'sales_rate_calс'

describe SalesRateCalc do
  describe '#perform' do
    let!(:shop) { create(:shop) }
    let!(:positive_items) do
      items = []
      5.times do |i|
        items[i] = create(:item, shop: shop, price: rand(10000))
        5.times { create(:action, shop: shop, user: create(:user), item: items[i], purchase_count: rand(20)) }
      end
      items
    end

    let!(:bad_item) { create(:item, shop: shop, price: 0) }

    subject { SalesRateCalc.perform }

    it 'calculate SR for all items in shop' do
      subject
      positive_items.each do |created_item|
        writed_item = shop.items.find(created_item[:id])
        assert(writed_item.sr!=0, "SR cannot be zero in positive items")
      end

      assert(shop.items.find(bad_item[:id]).sr==0, 'SR must be 0 on bad price items')

    end


  end
end
