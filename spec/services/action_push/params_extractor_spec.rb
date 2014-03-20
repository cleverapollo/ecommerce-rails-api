require 'spec_helper'

describe ActionPush::ParamsExtractor do
  describe '.extract' do
    context 'parameters validation' do
      before {
        @session = create(:session_with_user)
        @user = @session.user
        @shop = create(:shop)
        @action = 'view'
        @rating = 3
        @params = { ssid: @session.uniqid, event: @action, shop_id: @shop.uniqid, rating: @rating, item_id: [] }
      }

      subject { ActionPush::ParamsExtractor.extract(@params) }
      shared_examples 'raising error' do
        it 'raises error' do
          expect{ subject }.to raise_error(ArgumentError)
        end
      end

      context 'with all correct' do
        it 'returns openstruct wrapper' do
          expect(subject).to be_an_instance_of(OpenStruct)
        end

        it 'contains ssid' do
          expect(subject.ssid).to eq(@session.uniqid)
        end

        it 'contains user' do
          expect(subject.user).to eq(@user)
        end

        it 'contains shop' do
          expect(subject.shop).to eq(@shop)
        end

        it 'contains action' do
          expect(subject.action).to eq(@action)
        end

        it 'contains rating' do
          expect(subject.rating).to eq(@rating)
        end
      end

      context 'without ssid' do
        before { @params[:ssid] = nil }
        it_behaves_like 'raising error'
      end

      context 'without action' do
        before { @params[:event] = nil }
        it_behaves_like 'raising error'
      end

      context 'with unknown action' do
        before { @params[:event] = 'potato' }
        it_behaves_like 'raising error'
      end

      context 'without shop_id' do
        before { @params[:shop_id] = nil }
        it_behaves_like 'raising error'
      end

      context 'with incorrect rating' do
        before { @params[:rating] = 6 }
        it_behaves_like 'raising error'
      end

    end
  end
end
