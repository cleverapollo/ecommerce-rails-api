require 'rails_helper'

describe BrandLogger do

  describe '.track_event' do
    let!(:advertiser) { create(:advertiser) }
    let!(:brand_campaign) { create(:brand_campaign, advertiser: advertiser) }
    let!(:shop) { create(:shop) }
    let!(:brand_campaign_shop) { create(:brand_campaign_shop, shop: shop, brand_campaign: brand_campaign) }

    it 'creates statistics row on first view and updates it on next view' do
      expect(BrandCampaignStatistic.count).to eq(0)

      BrandLogger.track_view brand_campaign.id, shop.id, 'popular'
      expect(BrandCampaignStatistic.count).to eq(1)
      expect(BrandCampaignStatistic.first.views).to eq(1)
      brand_campaign_shop.reload
      expect(brand_campaign_shop.last_event_at).to_not be_nil
      expect(brand_campaign_shop.brand_campaign_statistics_events.count).to eq(1)

      BrandLogger.track_view brand_campaign.id, shop.id, 'interesting'
      expect(BrandCampaignStatistic.count).to eq(1)
      expect(BrandCampaignStatistic.first.views).to eq(2)
      brand_campaign_shop.reload
      expect(brand_campaign_shop.last_event_at).to_not be_nil
      expect(brand_campaign_shop.brand_campaign_statistics_events.count).to eq(2)
    end


    it 'creates statistics row on first click and updates it on next click' do
      expect(BrandCampaignStatistic.count).to eq(0)

      BrandLogger.track_click brand_campaign.id, shop.id, 'interesting'
      brand_campaign_shop.reload
      expect(BrandCampaignStatistic.count).to eq(1)
      expect(BrandCampaignStatistic.first.recommended_clicks).to eq(1)
      expect(brand_campaign_shop.brand_campaign_statistics_events.count).to eq(1)
      expect(brand_campaign_shop.brand_campaign_statistics_events.where('recommender IS NOT NULL').count).to eq(1)

      BrandLogger.track_click brand_campaign.id, shop.id, 'popular'
      brand_campaign_shop.reload
      expect(BrandCampaignStatistic.count).to eq(1)
      expect(BrandCampaignStatistic.first.recommended_clicks).to eq(2)
      expect(brand_campaign_shop.brand_campaign_statistics_events.count).to eq(2)
      expect(brand_campaign_shop.brand_campaign_statistics_events.where('recommender IS NOT NULL').count).to eq(2)

      BrandLogger.track_click brand_campaign.id, shop.id
      brand_campaign_shop.reload
      expect(BrandCampaignStatistic.count).to eq(1)
      expect(BrandCampaignStatistic.first.original_clicks).to eq(1)
      expect(brand_campaign_shop.brand_campaign_statistics_events.count).to eq(3)
      expect(brand_campaign_shop.brand_campaign_statistics_events.where('recommender IS NULL').count).to eq(1)

      BrandLogger.track_click brand_campaign.id, shop.id
      brand_campaign_shop.reload
      expect(BrandCampaignStatistic.count).to eq(1)
      expect(BrandCampaignStatistic.first.original_clicks).to eq(2)
      expect(brand_campaign_shop.brand_campaign_statistics_events.count).to eq(4)
      expect(brand_campaign_shop.brand_campaign_statistics_events.where('recommender IS NULL').count).to eq(2)
    end

    it 'creates statistics row on first purchase and updates it on next purchase' do
      expect(BrandCampaignStatistic.count).to eq(0)

      # Рекомендованная продажа
      BrandLogger.track_purchase brand_campaign.id, shop.id, 'interesting'
      brand_campaign_shop.reload
      expect(BrandCampaignStatistic.count).to eq(1)
      expect(BrandCampaignStatistic.first.recommended_purchases).to eq(1)
      expect(brand_campaign_shop.brand_campaign_statistics_events.count).to eq(1)
      expect(brand_campaign_shop.brand_campaign_statistics_events.where('recommender IS NOT NULL').count).to eq(1)

      # Обычная продажа
      BrandLogger.track_purchase brand_campaign.id, shop.id
      brand_campaign_shop.reload
      expect(BrandCampaignStatistic.count).to eq(1)
      expect(BrandCampaignStatistic.first.original_purchases).to eq(1)
      expect(brand_campaign_shop.brand_campaign_statistics_events.count).to eq(2)
      expect(brand_campaign_shop.brand_campaign_statistics_events.where('recommender IS NULL').count).to eq(1)
    end

  end
end
