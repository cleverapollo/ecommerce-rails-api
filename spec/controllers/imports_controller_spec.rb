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
    before { allow(ItemsImportWorker).to receive(:perform_async) }

    context 'insert' do
      it 'works' do
        post :products, shop_id: shop.uniqid, shop_secret: shop.secret, items: [{id: 1, name: 'Test', price: 1.0, currency: 'USD', url: 'http://google.com', picture: 'http://google.com/1.png', available: true, categories: []}]
        expect(response.code).to eq('204')
        expect(ItemsImportWorker).to have_received(:perform_async).once
      end
    end

    context 'update' do
      it 'works' do
        put :products, shop_id: shop.uniqid, shop_secret: shop.secret, items: [{id: 1, name: 'Test', price: 1.0, currency: 'USD', url: 'http://google.com', picture: 'http://google.com/1.png', available: true, categories: []}]
        expect(response.code).to eq('204')
        expect(ItemsImportWorker).to have_received(:perform_async).once
      end
    end

    context 'sync' do
      it 'works' do
        patch :products, shop_id: shop.uniqid, shop_secret: shop.secret, items: ['1']
        expect(response.code).to eq('204')
        expect(ItemsImportWorker).to have_received(:perform_async).once
      end
    end

    context 'delete' do
      it 'works' do
        delete :products, shop_id: shop.uniqid, shop_secret: shop.secret, items: [1]
        expect(response.code).to eq('204')
        expect(ItemsImportWorker).to have_received(:perform_async).once
      end
    end

    context 'access denied' do
      it 'declines' do
        post :products
        expect(response.code).to eq('400')
        expect(ItemsImportWorker).to_not have_received(:perform_async)
      end
    end

    it 'filter incorrect request' do
      get :products, shop_id: shop.uniqid, shop_secret: shop.secret, items: ['1']
      expect(response.code).to eq('400')
    end

    it 'convert method from params' do
      post :products, shop_id: shop.uniqid, shop_secret: shop.secret, items: ['1'], method: 'patch'
      expect(response.code).to eq('204')
      expect(ItemsImportWorker).to have_received(:perform_async).once
    end

  end

  context 'import locations' do
    before { allow(LocationsImportWorker).to receive(:perform_async) }

    it 'works' do
      put :locations, shop_id: shop.uniqid, shop_secret: shop.secret, locations: [{id: 1, name: 'Moscow', parent: nil}]
      expect(response.code).to eq('204')
      expect(LocationsImportWorker).to have_received(:perform_async).once
    end
    it 'error empty locations' do
      put :locations, shop_id: shop.uniqid, shop_secret: shop.secret
      expect(response.code).to eq('400')
      expect(LocationsImportWorker).to_not have_received(:perform_async)
    end
  end

  context 'import categories' do
    before { allow(CategoriesImportWorker).to receive(:perform_async) }

    it 'works' do
      put :categories, shop_id: shop.uniqid, shop_secret: shop.secret, categories: [{id: 1, name: 'T-Shirt', parent: nil}]
      expect(response.code).to eq('204')
      expect(CategoriesImportWorker).to have_received(:perform_async).once
    end
    it 'error empty categories' do
      put :categories, shop_id: shop.uniqid, shop_secret: shop.secret
      expect(response.code).to eq('400')
      expect(CategoriesImportWorker).to_not have_received(:perform_async)
    end
  end

  context 'job_worker' do
    it 'works' do
      post :job_worker, shop_id: shop.uniqid, shop_secret: shop.secret, code: 'KJhsd872Hj&^%3lkjJs', job_data: { class: 'SegmentDestroyWorker', args: nil }
      expect(response.code).to eq('200')
    end
  end


end
