require 'rails_helper'

RSpec.describe ShopLocation, :type => :model do
  let!(:shop) { create(:shop) }
  let(:locations) { Rees46ML::Tree.new }
  before do
    locations << Rees46ML::ShopLocation.new(id: '1', type: 'city', name: 'test')
    locations << Rees46ML::ShopLocation.new(id: '2', type: 'city', name: 'test2', parent_id: '1')
  end
  subject { ShopLocation.bulk_update(shop.id, locations) }

  it 'bulk update' do
    subject
    expect(ShopLocation.count).to eq(2)
  end
end
