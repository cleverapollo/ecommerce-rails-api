require 'rails_helper'

describe Recommendations::Params do
  let(:shop)    { create(:shop) }
  let(:session) { create(:session, :uniq, :with_user) }
  let(:user)    { session.user }

  before do
    # Возвращаем структуру ответа из Elastic
    allow_any_instance_of(Elasticsearch::Persistence::Repository::Class).to receive(:find).and_return(People::Profile.new)
  end

  subject { Recommendations::Params.extract(params) }

  shared_examples "raise error without param" do |attr|
    context "without #{ attr }" do
      it { expect{ Recommendations::Params.extract(params.except(attr)) }.to raise_error(Recommendations::IncorrectParams) }
    end
  end

  describe '.extract' do
    let(:params) do
      {
        ssid: session.code,
        shop_id: shop.uniqid,
        recommender_type: 'interesting',
        resize_image: '120'
      }
    end

    include_examples "raise error without param", :ssid
    include_examples "raise error without param", :shop_id
    include_examples "raise error without param", :recommender_type

    it { expect(subject.user).to eq(user) }
    it { expect(subject.shop).to eq(shop) }
    it { expect(subject.type).to eq(params[:recommender_type]) }
    it { expect(subject.resize_image).to eq(params[:resize_image]) }

    it {
      params[:resize_image] = '12'
      expect(subject.resize_image).to eq nil
    }

  end


  describe '.extract cart_item_id' do
    let(:params) do
      {
          ssid: session.code,
          shop_id: shop.uniqid,
          recommender_type: 'interesting',
          cart_item_id: ['1','2']
      }
    end
    let!(:item_1) { create(:item, shop: shop, uniqid: '1' )}
    let!(:item_2) { create(:item, shop: shop, uniqid: '2' )}

    it 'extracts cart_item_id when it is array' do
      expect(subject.cart_item_ids.sort).to eq([item_1.id, item_2.id])
    end

    it 'extracts cart_item_id when it is single value' do
      params[:cart_item_id] = item_1.uniqid
      expect(subject.cart_item_ids.sort).to eq([item_1.id])
    end

    it 'extracts cart_item_id when it is hash' do
      params[:cart_item_id] = {'0': 1, '1': 2}
      expect(subject.cart_item_ids.sort).to eq([item_1.id, item_2.id])
    end

    it 'extracts empty cart without error' do
      params[:cart_item_id] = ''
      expect(subject.cart_item_ids.sort).to eq([])
    end

  end

  describe '.extract search query' do

    let!(:params) do
      {
          ssid: session.code,
          shop_id: shop.uniqid,
          recommender_type: 'search',
          search_query: 'apple'
      }
    end

    it 'saves search query' do
      q = SearchQuery.count
      subject
      expect(SearchQuery.count > q).to be_truthy
    end

  end


  describe '.extract discount recommender' do

    let!(:params) do
      {
          ssid: session.code,
          shop_id: shop.uniqid,
          recommender_type: 'search',
          search_query: 'apple',
          discount: true
      }
    end

    it 'with discount' do
      expect(subject.discount).to be_truthy
    end

    it 'without discount' do
      params.delete :discount
      expect(subject.discount).to be_falsey
    end

  end

  context '.segments' do
    let(:params) do
      {
        ssid: session.code,
        shop_id: shop.uniqid,
        recommender_type: 'interesting',
        resize_image: '120',
        segments: {'1' => '3'}
      }
    end

    it '.extract' do
      expect(subject.segments).to eq(['1_3'])
    end
  end

  context '.extract extract_avg_viewed_price' do
    let!(:item1) { create(:item, shop: shop, price: 100, category_ids: ['1']) }
    let!(:item2) { create(:item, shop: shop, price: 50, category_ids: ['1']) }
    let!(:item3) { create(:item, shop: shop, price: 10, category_ids: ['5']) }
    let!(:action1) { create(:action_cl, shop: shop, session: session, event: 'view', object_type: 'Item', object_id: item1.uniqid, price: item1.price) }
    let!(:action2) { create(:action_cl, shop: shop, session: session, event: 'view', object_type: 'Item', object_id: item2.uniqid, price: item2.price) }
    let!(:action3) { create(:action_cl, shop: shop, session: session, event: 'view', object_type: 'Item', object_id: item3.uniqid, price: item3.price) }
    let(:params) do
      {
        ssid: session.code,
        shop_id: shop.uniqid,
        recommender_type: 'popular',
        price_sensitive: 'true',
        category: '1',
      }
    end

    it '.extract' do
      p = subject
      expect(p.price_sensitive).to eq(75.0)
      expect(p.price_range).to eq(0.1)
    end
  end


end
