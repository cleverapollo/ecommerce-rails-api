require 'spec_helper'

describe Recommendations::ParamsExtractor do
  describe '.extract' do
    before do
      @shop = create(:shop)
      @session = create(:session_with_user)
      @user = @session.user

      @params = {
        ssid: @session.uniqid,
        shop_id: @shop.uniqid,
        recommender_type: 'interesting'
      }
    end

    subject { Recommendations::ParamsExtractor.extract(@params) }

    context 'params validation' do
      [:ssid, :shop_id, :recommender_type].each do |attr|
        it "raises an exception without a #{attr}" do
          @params[attr] = nil
          expect{ subject }.to raise_error(Recommendations::Error)
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
end
