require 'rails_helper'

describe Actions::Tracker do

  context '.track item' do
    let(:session)            { create(:session_with_user, code: rand(1000)) }
    let(:user)               { session.user }
    let!(:customer)          { create(:customer) }
    let!(:shop)              { create(:shop, customer: customer, url:'http://example.com/') }
    let!(:item) { create(:item, shop: shop, uniqid: 'T4') }

    let(:params1) { OpenStruct.new({
        session: session,
        current_session_code: '1',
        shop: shop,
        action: 'view',
        items: [item],
        request: OpenStruct.new({referer: 'test', user_agent: 'test agent'})
    }) }

    let(:params2) { OpenStruct.new({
        session: session,
        current_session_code: '1',
        shop: shop,
        action: 'search',
        raw: { search_query: 'test_search' },
        request: OpenStruct.new({referer: 'test', user_agent: 'test agent'})
    }) }

    subject(:track_subject) { Actions::Tracker.new(params1).track }
    subject(:search_query_subject) { Actions::Tracker.new(params2).track }

    it 'track' do

      allow(ClickhouseQueue).to receive(:actions).with({
          session_id: params1.session.id,
          current_session_code: params1.current_session_code,
          shop_id: params1.shop.id,
          event: params1.action,
          object_type: Item,
          object_id: item.uniqid,
          recommended_by: nil,
          recommended_code: nil,
          price: item.price,
          brand: item.brand,
          referer: params1.request.referer,
          useragent: params1.request.user_agent,
      })
      track_subject
    end


    it 'track_search' do

      allow(ClickhouseQueue).to receive(:actions).with({
          session_id: params2.session.id,
          current_session_code: params2.current_session_code,
          shop_id: params2.shop.id,
          event: 'view',
          object_type: 'Search',
          object_id: 'test_search',
          recommended_by: nil,
          recommended_code: nil,
          price: 0,
          brand: nil,
          referer: params2.request.referer,
          useragent: params2.request.user_agent,
      })
      search_query_subject
    end
  end
end
