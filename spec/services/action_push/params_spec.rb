require 'rails_helper'

describe ActionPush::Params do
  describe '.extract' do
    context 'parameters validation' do
      let(:session)            { create(:session_with_user, code: rand(1000)) }
      let(:user)               { session.user }
      let!(:customer)          { create(:customer) }
      let!(:shop)              { create(:shop, customer: customer, url:'http://example.com/') }
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
          item_id: [item_with_slash.uniqid, item_without_slash.uniqid],
          url: [item_with_slash.url, item_without_slash.url],
          price: [300, 499],
          image_url: [item_with_slash.image_url, item_without_slash.image_url],
          order_id: 111,
          order_price: 333,
          cosmetics_gender: ['m'],
          fashion_gender: ['f'],
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
      it { expect(subject.order_id).to eq(111) }
      it { expect(subject.order_price).to eq(333) }

      it 'item with save genders' do
        subject
        expect(item_with_slash.reload.cosmetic_gender).to eq('m')
        expect(item_with_slash.reload.fashion_gender).to eq('f')
        expect(item_without_slash.reload.cosmetic_gender).to be_nil
        expect(item_without_slash.reload.fashion_gender).to be_nil
      end

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

      context 'with a bit amount' do
        let(:params) do
          {
            ssid: session.code,
            event: 'purchase',
            shop_id: shop.uniqid,
            rating: rating,
            item_id: [item_with_slash.uniqid, item_without_slash.uniqid],
            amount: [100000000000000.00, 1],
            url: [item_with_slash.url, item_without_slash.url],
            price: [300, 499],
            image_url: [item_with_slash.image_url, item_without_slash.image_url],
            order_id: 111,
            order_price: 333
          }
        end

        it 'with max amount 1000' do
          expect(subject.items[0].amount).to eq(1000)
          expect(subject.items[1].amount).to eq(1)
        end
      end

    end


    context 'process fashion_size' do

      let(:session)            { create(:session_with_user, code: rand(1000)) }
      let(:user)               { session.user }
      let!(:customer)          { create(:customer) }
      let!(:shop)              { create(:shop, customer: customer, url:'http://example.com/', yml_file_url: 'http://ya.ru', yml_loaded: true, yml_errors: 0) }
      let(:action)             { 'view' }
      let(:rating)             { 3 }
      let(:item)               { create(:item, shop: shop, url:'/item_01', image_url:'/image_01', price: 500, is_fashion: true, fashion_gender: 'f', fashion_wear_type: 'shoe') }

      let(:params) do
        {
            ssid: session.code,
            event: action,
            shop_id: shop.uniqid,
            rating: rating,
            item_id: [item.uniqid],
            url: [item.url],
            price: [300],
            image_url: [item.image_url],
            fashion_size: ['41']
        }
      end

      subject { ActionPush::Params.extract(params) }

      it 'extracts russian fashion size' do
        expect(subject.niche_attributes[item.id][:fashion_size]).to eq '41'
      end


      it 'extracts american fashion size' do
        params[:fashion_size][0] = 'XS'
        expect(subject.niche_attributes[item.id][:fashion_size].to_s).to eq '30'
      end

    end


    context 'process source' do

      let(:session)            { create(:session_with_user, code: rand(1000)) }
      let(:user)               { session.user }
      let!(:customer)          { create(:customer) }
      let!(:shop)              { create(:shop, customer: customer, url:'http://example.com/') }
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
            item_id: [item_with_slash.uniqid, item_without_slash.uniqid],
            url: [item_with_slash.url, item_without_slash.url],
            price: [300, 499],
            image_url: [item_with_slash.image_url, item_without_slash.image_url],
        }
      end

      subject { ActionPush::Params.extract(params) }

      it 'extracts trigger mail code' do
        code = SecureRandom.uuid
        params[:source] = {from: 'trigger_mail', code: code}.to_json
        expect(subject.trigger_mail_code).to eq code
      end

      it 'extracts digest mail code' do
        code = SecureRandom.uuid
        params[:source] = {from: 'digest_mail', code: code}.to_json
        expect(subject.digest_mail_code).to eq code
      end

      it 'extracts web push trigger code' do
        code = SecureRandom.uuid
        params[:source] = {from: 'web_push_trigger', code: code}.to_json
        expect(subject.web_push_trigger_code).to eq code
      end

      it 'extracts web push digest code' do
        code = SecureRandom.uuid
        params[:source] = {from: 'web_push_digest', code: code}.to_json
        expect(subject.web_push_digest_code).to eq code
      end

      it 'extracts remarketing code' do
        code = SecureRandom.uuid
        params[:source] = {from: 'r46_returner', code: code}.to_json
        expect(subject.r46_returner_code).to eq code
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
