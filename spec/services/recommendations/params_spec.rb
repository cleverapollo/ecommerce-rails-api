require 'rails_helper'

describe Recommendations::Params do
  describe '.extract' do
    before do
      @shop = create(:shop)
      @session = create(:session_with_user)
      @user = @session.user

      @params = {
        ssid: @session.code,
        shop_id: @shop.uniqid,
        recommender_type: 'interesting'
      }
    end

    subject { Recommendations::Params.extract(@params) }

    context 'params validation' do
      [:ssid, :shop_id, :recommender_type].each do |attr|
        it "raises an exception without a #{attr}" do
          @params[attr] = nil
          expect{ subject }.to raise_error(Recommendations::IncorrectParams)
        end
      end
    end

    context 'output data' do
      it 'have user' do
        expect(subject.user).to eq(@user)
      end

      it 'have shop' do
        expect(subject.shop).to eq(@shop)
      end

      it 'have type' do
        expect(subject.type).to eq(@params[:recommender_type])
      end
    end
  end

  describe '.extract by email' do
    before do
      @shop = create(:shop)
      @session = create(:session_with_user)
      @user = @session.user
      @client = create(:client, user: @user, email: 'kechinoff@gmail.com', shop: @shop)

      @params = {
          email: 'kechinoff@gmail.com',
          shop_id: @shop.uniqid,
          recommender_type: 'interesting'
      }
    end

    subject { Recommendations::Params.extract(@params) }

    context 'params validation' do

      it 'raises an exception without a email' do
        @params[:email] = nil
        expect{ subject }.to raise_error(Recommendations::IncorrectParams)
      end

    end

    context 'output data' do
      it 'have user' do
        expect(subject.user).to eq(@user)
      end
    end

  end


end
