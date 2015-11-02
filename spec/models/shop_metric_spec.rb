require 'rails_helper'

RSpec.describe ShopMetric, :type => :model do

  describe '.create' do

    let!(:shop) { create(:shop) }

    it 'creates shop metric' do
      shop_metric = ShopMetric.new shop_id: shop.id, date: Date.current
      expect{ shop_metric.save! }.to change(ShopMetric, :count).from(0).to(1)
    end

    it 'not creates shop metric without absent data' do
      shop_metric = ShopMetric.new shop_id: shop.id, date: Date.current, revenue: nil
      expect{ shop_metric.save! }.to raise_exception
    end

    it 'not creates shop metric without wrong data' do
      shop_metric = ShopMetric.new shop_id: shop.id, date: Date.current, revenue: -1
      expect{ shop_metric.save! }.to raise_exception
    end


  end


end
