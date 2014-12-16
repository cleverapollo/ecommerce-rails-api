require 'spec_helper'

describe ImportsController do
  describe 'GET disable' do
    let(:shop) { create(:shop) }
    let(:item) { create(:item, shop: shop) }

    context 'when one id passed' do
      it 'disables given item' do
        get :disable, shop_id: shop.uniqid, shop_secret: shop.secret, item_ids: item.uniqid
        expect(item.reload.is_available).to be_false
      end
    end

    context 'when many ids passed' do
      let(:another_item) { create(:item, shop: shop) }

      it 'disables given items' do
        get :disable, shop_id: shop.uniqid, shop_secret: shop.secret, item_ids: "#{item.uniqid},#{another_item.uniqid}"
        expect(item.reload.is_available).to be_false
        expect(another_item.reload.is_available).to be_false
      end
    end

    context 'when no id passed' do
      it 'responds with 200' do
        get :disable, shop_id: shop.uniqid, shop_secret: shop.secret
        expect(response.code).to eq('200')
      end
    end

    context 'when not existent id passed' do
      it 'responds with 200' do
        get :disable, shop_id: shop.uniqid, shop_secret: shop.secret, item_ids: 'potato'
        expect(response.code).to eq('200')
      end
    end
  end
end
