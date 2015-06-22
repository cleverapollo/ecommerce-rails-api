require 'rails_helper'

describe ActionPush::Params do
  describe '.extract' do
    context 'parameters validation' do
      before {
        @session = create(:session_with_user)
        @user = @session.user
        @shop = create(:shop, url:'http://example.com/')
        @action = 'view'
        @rating = 3
        @item_with_slash = create(:item, shop: @shop, url:'/item_01', image_url:'/image_01')
        @item_without_slash = create(:item, shop: @shop, url:'item_02', image_url:'image_02')
        @params = { ssid: @session.code, event: @action, shop_id: @shop.uniqid, rating: @rating, item_id: [@item_with_slash.id, @item_without_slash.id], url: [@item_with_slash.url, @item_without_slash.url], image_url: [@item_with_slash.image_url, @item_without_slash.image_url] }
      }

      subject { ActionPush::Params.extract(@params) }
      shared_examples 'raising error' do
        it 'raises error' do
          expect{ subject }.to raise_error(ActionPush::Error)
        end
      end

      context 'with all correct' do
        it 'returns ActionPush::Params object' do
          expect(subject).to be_an_instance_of(ActionPush::Params)
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

        it 'correct item url' do
          expect(subject.items[0].url).to eq('http://example.com/item_01')
          expect(subject.items[1].url).to eq('http://example.com/item_02')
        end

        it 'correct image_url' do
          expect(subject.items[0].image_url).to eq('http://example.com/image_01')
          expect(subject.items[1].image_url).to eq('http://example.com/image_02')
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
