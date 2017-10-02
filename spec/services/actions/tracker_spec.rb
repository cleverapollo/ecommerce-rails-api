require 'rails_helper'

describe Actions::Tracker do

  context '.track item' do
    let(:session)            { create(:session_with_user, code: rand(1000)) }
    let(:user)               { session.user }
    let!(:customer)          { create(:customer) }
    let!(:shop)              { create(:shop, customer: customer, url:'http://example.com/') }
    let!(:item) { create(:item, shop: shop, uniqid: 'T4') }
    let(:params) { OpenStruct.new({
        session: session,
        current_session_code: '1',
        shop: shop,
        action: 'view',
        items: [item],
        request: OpenStruct.new({referer: 'test', user_agent: 'test agent'})
    }) }

    subject { Actions::Tracker.new(params).track }

    it 'track' do
      allow(ClickhouseQueue).to receive(:push).with('actions', {
          session_id: params.session.id,
          current_session_code: params.current_session_code,
          shop_id: params.shop.id,
          event: params.action,
          object_type: Item,
          object_id: item.uniqid,
          recommended_by: nil,
          recommended_code: nil,
          price: item.price,
          brand: item.brand,
          referer: params.request.referer,
          useragent: params.request.user_agent,
      })
      subject
    end
  end
end
