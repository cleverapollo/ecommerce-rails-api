require 'rails_helper'

describe ActionPush::Params do
  describe '.extract' do
    context 'parameters validation' do
      let(:session)            { create(:session_with_user, code: rand(1000)) }
      let(:user)               { session.user }
      let(:shop)               { create(:shop, url:'http://example.com/') }
      let(:action)             { 'view' }
      let(:rating)             { 3 }
      let(:item_with_slash)    { create(:item, shop: shop, url:'/item_01', image_url:'/image_01', price: 500) }
      let(:item_without_slash) { create(:item, shop: shop, url:'item_02', image_url:'image_02', price: 700) }

      let(:params) do
        {
          ssid: session.code,
          event: action,
          shop_id: shop.uniqid,
          rating: rating,
          item_id: [item_with_slash.id, item_without_slash.id],
          url: [item_with_slash.url, item_without_slash.url],
          price: [300, 499],
          image_url: [item_with_slash.image_url, item_without_slash.image_url]
        }
      end

      subject { ActionPush::Params.extract(params) }

      shared_examples 'raising error' do
        it { expect{ subject }.to raise_error(ActionPush::Error) }
      end

      it { expect(subject).to be_an_instance_of(ActionPush::Params) }
      it { expect(subject.user).to eq(user) }
      it { expect(subject.shop).to eq(shop) }
      it { expect(subject.action).to eq(action) }
      it { expect(subject.rating).to eq(rating) }
      it { expect(subject.items[0].url).to eq('http://example.com/item_01') }
      it { expect(subject.items[1].url).to eq('http://example.com/item_02') }
      it { expect(subject.items[0].image_url).to eq('http://example.com/image_01') }
      it { expect(subject.items[1].image_url).to eq('http://example.com/image_02') }
      it { expect(subject.items[0].price).to eq(300) }
      it { expect(subject.items[1].price).to eq(499) }

      context 'without ssid' do
        subject { ActionPush::Params.extract(params.except(:ssid)) }

        it_behaves_like 'raising error'
      end

      context 'without action' do
        subject { ActionPush::Params.extract(params.except(:event)) }

        it_behaves_like 'raising error'
      end

      context 'without shop_id' do
        subject { ActionPush::Params.extract(params.except(:shop_id)) }

        it_behaves_like 'raising error'
      end

      context 'with unknown action' do
        before { params[:event] = 'potato' }

        it_behaves_like 'raising error'
      end

      context 'with incorrect rating' do
        subject { ActionPush::Params.extract(params) }
        before { params[:rating] = 6 }
        it_behaves_like 'raising error'
      end

    end


    # TODO: решить эту проблему http://y.mkechinov.ru/issue/REES-2336
    # context 'parameters validation when shop have valid and processed YML' do
    #
    #   let(:session)            { create(:session_with_user, code: rand(1000)) }
    #   let(:user)               { session.user }
    #   let(:shop)               { create(:shop, url:'http://example.com/', yml_file_url: 'http://example.com', yml_loaded: true, yml_errors: 0) }
    #   let(:action)             { 'view' }
    #   let(:rating)             { 3 }
    #   let(:item_with_slash)    { create(:item, shop: shop, url:'/item_01', image_url:'/image_01', price: 500, locations: ['1' => 300, '2' => 500]) }
    #   let(:item_without_slash) { create(:item, shop: shop, url:'item_02', image_url:'image_02', price: 700, locations: ['1' => 499, '2' => 600]) }
    #
    #   let(:params) do
    #     {
    #         ssid: session.code,
    #         event: action,
    #         shop_id: shop.uniqid,
    #         rating: rating,
    #         item_id: [item_with_slash.id, item_without_slash.id],
    #         url: [item_with_slash.url, item_without_slash.url],
    #         locations: ['1', '2'],
    #         price: [300, 499],
    #         image_url: [item_with_slash.image_url, item_without_slash.image_url]
    #     }
    #   end
    #
    #   subject { ActionPush::Params.extract(params) }
    #
    #   context 'price' do
    #     it { expect(subject.items[0].price).to eq(300) }
    #     it { expect(subject.items[1].price).to eq(499) }
    #   end
    #
    # end

  end
end
