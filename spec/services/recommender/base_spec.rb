require 'rails_helper'

describe Recommender::Base do
  describe '#items_in_shop' do
    let!(:shop)  { create(:shop) }
    let(:result) { Recommender::Base.new(params).items_in_shop }
    let(:params) { OpenStruct.new(shop: shop, locations: ['1'], brand: ["samsung"]) }

    specify do
      a = create(:item, :recommendable, :widgetable, shop: shop)
      expect(Recommender::Base.new(params).items_in_shop.pluck(:id)).to_not include(a.id)

      b = create(:item, :recommendable, :widgetable, shop: shop, location_ids: params.locations)
      expect(Recommender::Base.new(params).items_in_shop.pluck(:id)).to include(b.id)

      c = create(:item, :recommendable, :widgetable, shop: shop, brand: params.brand)
      expect(Recommender::Base.new(params).items_in_shop.pluck(:id)).to_not include(c.id)

      d = create(:item, :recommendable, :widgetable, shop: shop, location_ids: params.locations, brand: params.brand)
      expect(Recommender::Base.new(params).items_in_shop.pluck(:id)).to include(d.id)

      e = create(:item, :recommendable, :widgetable, shop: shop, location_ids: params.locations, seasonality: [1.month.ago.to_date.month, Date.current.month])
      expect(Recommender::Base.new(params).items_in_shop.pluck(:id)).to include(e.id)

      f = create(:item, :recommendable, :widgetable, shop: shop, location_ids: params.locations, seasonality: [1.month.ago.to_date.month])
      expect(Recommender::Base.new(params).items_in_shop.pluck(:id)).to_not include(f.id)
    end
  end
end
