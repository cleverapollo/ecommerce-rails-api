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
        recommender_type: 'interesting'
      } 
    end

    include_examples "raise error without param", :ssid
    include_examples "raise error without param", :shop_id
    include_examples "raise error without param", :recommender_type

    it { expect(subject.user).to eq(user) }
    it { expect(subject.shop).to eq(shop) }
    it { expect(subject.type).to eq(params[:recommender_type]) }
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


  describe '.extract modification' do
    let!(:shop_with_child)    { create(:shop, enabled_child: true) }
    let!(:shop_without_child)    { create(:shop, enabled_child: false) }

    let!(:params) do
      {
          ssid: session.code,
          shop_id: shop_with_child.uniqid,
          recommender_type: 'interesting',
          modification: 'child'
      }
    end

    it { expect(subject.modification).to eq('child') }

    let!(:params) do
      {
          ssid: session.code,
          shop_id: shop_without_child.uniqid,
          recommender_type: 'interesting',
          modification: 'child'
      }
    end

    it { expect(subject.modification).to eq(nil) }

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


end
