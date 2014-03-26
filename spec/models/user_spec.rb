require 'spec_helper'

describe User do
  describe '#item_ids_bought_in_shop' do
    before { @user = create(:user) }
    before { @shop = create(:shop) }
    before { @action = create(:action, shop: @shop, user: @user, item_id: 1, purchase_count: 1)}
    it 'returns bought item ids' do
      expect(@user.items_ids_bought_in_shop(@shop)).to eq([1])
    end
  end
end
