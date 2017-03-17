require 'rails_helper'

describe ImportsController do
  let(:shop) { create(:shop) }

  describe 'GET disable' do
    let(:item) { create(:item, shop: shop) }

    context 'when one id passed' do
      it 'disables given item' do
        get :disable, shop_id: shop.uniqid, shop_secret: shop.secret, item_ids: item.uniqid
        expect(item.reload.is_available).to be_falsey
      end
    end

    context 'when many ids passed' do
      let(:another_item) { create(:item, shop: shop) }

      it 'disables given items' do
        get :disable, shop_id: shop.uniqid, shop_secret: shop.secret, item_ids: "#{item.uniqid},#{another_item.uniqid}"
        expect(item.reload.is_available).to be_falsey
        expect(another_item.reload.is_available).to be_falsey
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


  describe 'import products' do

    context 'insert' do
      it 'works' do
        post :products, shop_id: shop.uniqid, shop_secret: shop.secret
        expect(response.code).to eq('204')
      end
    end

    context 'update' do
      it 'works' do
        put :products, shop_id: shop.uniqid, shop_secret: shop.secret
        expect(response.code).to eq('204')
      end
    end

    context 'delete' do
      it 'works' do
        delete :products, shop_id: shop.uniqid, shop_secret: shop.secret
        expect(response.code).to eq('204')
      end
    end

    context 'access denied' do
      it 'declines' do
        post :products
        expect(response.code).to eq('400')
      end
    end

  end

  context 'job_worker' do
    it 'works' do
      post :job_worker, shop_id: shop.uniqid, shop_secret: shop.secret, code: 'KJhsd872Hj&^%3lkjJs', job_data: { class: 'SegmentDestroyWorker', args: nil }
      expect(response.code).to eq('200')
    end
  end


end
