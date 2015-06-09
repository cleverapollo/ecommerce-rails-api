require 'rails_helper'

describe BrandLogger do

  describe '.track_event' do
    let!(:advertiser) { create(:advertiser) }
    let!(:order_recommended) {create(:order, items:[create(:item)], recommended:true)}
    let!(:order_not_recommended) {create(:order, items:[create(:item)], recommended:false)}

    it 'creates statistics row on first view and updates it on next view' do
      expect(AdvertiserStatistic.count).to eq(0)

      BrandLogger.track_view advertiser.id
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.views).to eq(1)

      BrandLogger.track_view advertiser.id
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.views).to eq(2)
    end


    it 'creates statistics row on first click and updates it on next click' do
      expect(AdvertiserStatistic.count).to eq(0)

      BrandLogger.track_click advertiser.id
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.clicks).to eq(1)

      BrandLogger.track_click advertiser.id
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.clicks).to eq(2)
    end

    it 'creates statistics row on first purchase and updates it on next purchase' do
      expect(AdvertiserStatistic.count).to eq(0)

      # Рекомендованная продажа
      BrandLogger.track_purchase advertiser.id, order_recommended
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.recommended_purchases).to eq(1)

      # Обычная продажа
      BrandLogger.track_purchase advertiser.id, order_not_recommended
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.original_purchases).to eq(1)
    end

  end
end
