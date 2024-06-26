require 'rails_helper'

describe OrdersImportWorker do
  let!(:shop) { create(:shop) }
  let!(:params) {
    {
      'shop_id' => shop.uniqid, 'shop_secret' => shop.secret,

      'orders' => [
        {
          'id' => '123', 'user_id' => '456', 'user_email' => 'test@test.te', 'date' => 1.month.ago.to_i.to_s,
          'items' => [ { 'id' => '888', 'price' => '1500.44', 'category_ids' => ['55'], 'is_available' => '1', 'amount' => '4' } ]
        },
        {
            'id' => '124', 'user_id' => '457', 'user_email' => '', 'date' => 1.month.ago.to_i.to_s,
            'items' => [ { 'id' => '888', 'price' => '1500.44', 'category_ids' => ['55'], 'is_available' => '1', 'amount' => '4' } ]
        },
        {
            'id' => '1245', 'user_id' => '4575', 'user_email' => 'test@test.te', 'date' => 1.month.ago.to_i.to_s,
            'items' => [ { 'id' => '8889', 'price' => '15009.44', 'category_ids' => ['55'], 'is_available' => '1', 'amount' => '4' } ]
        }
      ]
    }
  }

  it 'persists given orders' do
    OrdersImportWorker.new.perform(params)

    # Check users
    s_u = shop.clients.first!
    user = s_u.user
    expect(s_u.external_id).to eq(params['orders'][0]['user_id'])
    expect(s_u.email).to eq(params['orders'][0]['user_email'])
    expect(shop.shop_emails.first.email).to eq(params['orders'][0]['user_email'])

    # Check orders
    order = shop.orders.first!
    expect(order.uniqid).to eq(params['orders'][0]['id'])
    expect(order.date).to eq(Time.at(params['orders'][0]['date'].to_i))
    expect(order.user_id).to eq(s_u.user_id)

    # Check items
    item_raw = params['orders'][0]['items'][0]
    item = Item.find_by!(shop_id: shop.id, uniqid: item_raw['id'])
    expect(item.price).to eq(item_raw['price'].to_f)
    expect(item.category_ids).to eq(item_raw['categories'])
    expect(item.is_available).to eq(item_raw['is_available'] == '1')

    expect(shop.clients.where(external_id: '457').first.email).to eq(nil)
    expect(Client.where(email: 'test@test.te').count).to eq(1)
    expect(shop.reload.last_orders_import_at.present?).to eq(true)
  end
end
