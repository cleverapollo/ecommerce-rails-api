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

    # it 'track' do
    #   subject
    #   action = ActionCl.first
    #   expect(action.session_id).to eq(session.id)
    #   expect(action.shop_id).to eq(shop.id)
    #   expect(action.current_session_code).to eq('1')
    #   expect(action.event).to eq('view')
    #   expect(action.object_type).to eq('Item')
    #   expect(action.object_id).to eq(item.uniqid)
    # end
  end
end
