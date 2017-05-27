require 'rails_helper'

describe UserMergerInShopWorker do
  let(:shop) { create(:shop) }
  let!(:client_1) {create(:client, user: User.create, email: 'email@example.ru', shop_id: shop.id)}
  let!(:client_2) {create(:client, user: User.create, email: 'email@example.ru', shop_id: shop.id)}
  let!(:client_3) {create(:client, user: User.create, email: 'email@example.ru', shop_id: shop.id)}

  subject { UserMergerInShopWorker.new.perform(shop.id) }

  it 'merge shop clients' do
    subject

    expect(Client.last.id).to eq(client_1.id)
    expect(shop.clients.count).to eq(1)

    expect(User.count).to eq(1)
    expect(User.last.id).to eq(client_1.user_id)
  end
end
