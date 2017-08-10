require 'rails_helper'

describe SearchEngine::Params do
  let(:shop)    { create(:shop) }
  let(:session) { create(:session, :uniq, :with_user) }
  let(:user)    { session.user }

  subject { SearchEngine::Params.extract(params) }

  shared_examples "raise error without param" do |attr|
    context "without #{ attr }" do
      it { expect{ SearchEngine::Params.extract(params.except(attr)) }.to raise_error(SearchEngine::IncorrectParams) }
    end
  end

  describe '.extract' do
    let(:params) do
      {
        ssid: session.code,
        shop_id: shop.uniqid,
        type: 'instant_search',
        search_query: 'laque'
      }
    end

    include_examples "raise error without param", :ssid
    include_examples "raise error without param", :shop_id
    include_examples "raise error without param", :type
    include_examples "raise error without param", :search_query

    it { expect(subject.user).to eq(user) }
    it { expect(subject.shop).to eq(shop) }
    it { expect(subject.type).to eq(params[:type]) }
    it { expect(subject.search_query).to eq(params[:search_query]) }

  end


  describe '.extract cart_item_id' do
    let(:params) do
      {
          ssid: session.code,
          shop_id: shop.uniqid,
          type: 'instant_search',
          cart_item_id: ['1','2'],
          search_query: 'query'
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
        type: 'instant_search',
        search_query: 'laque'
      }
    end

    include_examples "raise error without param", :email

    it{ expect(subject.user).to eq(user) }
  end


  context '.blank user' do
    let(:params) do
      {
        ssid: session.code,
        shop_id: shop.uniqid,
        type: 'instant_search',
        search_query: 'lua'
      }
    end

    it '.extract and create new user' do
      user.delete
      expect(subject.user).not_to be_nil
      expect(subject.user).not_to eq(user)
    end

  end



end
