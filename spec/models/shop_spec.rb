require 'spec_helper'

describe Shop do
  describe '#available_item_ids' do
    before { @shop = create(:shop) }
    before { @item = create(:item, shop: @shop) }

    it 'returns available item ids' do
      expect(@shop.available_item_ids).to match_array([@item.id])
    end
  end
end
