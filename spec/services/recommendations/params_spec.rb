require 'rails_helper'

describe Recommendations::Params do
  let(:shop)    { create(:shop) }
  let(:session) { create(:session, :uniq, :with_user) }
  let(:user)    { session.user }

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


  describe '.extract by email' do
    let(:client) { create(:client, user: user, email: 'kechinoff@gmail.com', shop: shop) }

    let(:params) do
      {
        email: client.email,
        shop_id: shop.uniqid,
        recommender_type: 'interesting'
      }
    end

    include_examples "raise error without param", :email

    it{ expect(subject.user).to eq(user) }
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

  context '.blank user' do
    let(:params) do
      {
        ssid: session.code,
        shop_id: shop.uniqid,
        recommender_type: 'interesting',
        resize_image: '120'
      }
    end

    it '.extract and create new user' do
      user.delete
      expect(subject.user).not_to be_nil
      expect(subject.user).not_to eq(user)
    end

  end


end
