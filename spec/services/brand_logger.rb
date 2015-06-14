require 'rails_helper'

describe BrandLogger do

  describe '.track_event' do
    let!(:advertiser) { create(:advertiser) }
    let!(:shop) { create(:shop) }
    let!(:advertiser_shop) { create(:advertiser_shop, shop: shop, advertiser: advertiser) }

    it 'creates statistics row on first view and updates it on next view' do
      expect(AdvertiserStatistic.count).to eq(0)

      BrandLogger.track_view advertiser.id, shop.id, 'popular'
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.views).to eq(1)
      advertiser_shop.reload
      expect(advertiser_shop.last_event_at).to_not be_nil
      expect(advertiser_shop.advertiser_statistics_events.count).to eq(1)

      BrandLogger.track_view advertiser.id, shop.id, 'interesting'
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.views).to eq(2)
      advertiser_shop.reload
      expect(advertiser_shop.last_event_at).to_not be_nil
      expect(advertiser_shop.advertiser_statistics_events.count).to eq(2)
    end


    it 'creates statistics row on first click and updates it on next click' do
      expect(AdvertiserStatistic.count).to eq(0)

      BrandLogger.track_click advertiser.id, shop.id, 'interesting'
      advertiser_shop.reload
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.recommended_clicks).to eq(1)
      expect(advertiser_shop.advertiser_statistics_events.count).to eq(1)
      expect(advertiser_shop.advertiser_statistics_events.where('recommender IS NOT NULL').count).to eq(1)

      BrandLogger.track_click advertiser.id, shop.id, 'popular'
      advertiser_shop.reload
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.recommended_clicks).to eq(2)
      expect(advertiser_shop.advertiser_statistics_events.count).to eq(2)
      expect(advertiser_shop.advertiser_statistics_events.where('recommender IS NOT NULL').count).to eq(2)

      BrandLogger.track_click advertiser.id, shop.id
      advertiser_shop.reload
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.original_clicks).to eq(1)
      expect(advertiser_shop.advertiser_statistics_events.count).to eq(3)
      expect(advertiser_shop.advertiser_statistics_events.where('recommender IS NULL').count).to eq(1)

      BrandLogger.track_click advertiser.id, shop.id
      advertiser_shop.reload
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.original_clicks).to eq(2)
      expect(advertiser_shop.advertiser_statistics_events.count).to eq(4)
      expect(advertiser_shop.advertiser_statistics_events.where('recommender IS NULL').count).to eq(2)
    end

    it 'creates statistics row on first purchase and updates it on next purchase' do
      expect(AdvertiserStatistic.count).to eq(0)

      # Рекомендованная продажа
      BrandLogger.track_purchase advertiser.id, shop.id, 'interesting'
      advertiser_shop.reload
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.recommended_purchases).to eq(1)
      expect(advertiser_shop.advertiser_statistics_events.count).to eq(1)
      expect(advertiser_shop.advertiser_statistics_events.where('recommender IS NOT NULL').count).to eq(1)

      # Обычная продажа
      BrandLogger.track_purchase advertiser.id, shop.id
      advertiser_shop.reload
      expect(AdvertiserStatistic.count).to eq(1)
      expect(AdvertiserStatistic.first.original_purchases).to eq(1)
      expect(advertiser_shop.advertiser_statistics_events.count).to eq(2)
      expect(advertiser_shop.advertiser_statistics_events.where('recommender IS NULL').count).to eq(1)
    end

  end
end
