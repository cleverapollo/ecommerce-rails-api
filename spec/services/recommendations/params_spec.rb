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
end
