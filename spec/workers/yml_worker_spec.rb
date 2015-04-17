require 'rails_helper'

describe YmlWorker do
  describe '#perform' do
    let!(:shop) { create(:shop) }
    before {
      allow_any_instance_of(Yml).to receive(:get).and_yield(File.open("#{Rails.root}/spec/files/yml.xml", 'rb'))
    }
    subject { YmlWorker.new.perform(shop.id) }

    it 'creates new item' do
      subject

      new_item = shop.items.find_by(uniqid: '2000')
      {
        url: 'http://example.com/item/2000',
        price: 900,
        categories: ['2', '3'],
        image_url: 'http://example.com/item/2000.jpg',
        name: 'New item',
        description: 'New item description'
      }.each{|attr, value| expect(new_item.public_send(attr)).to eq(value) }
    end

    it 'updates existing item' do
      existing_item = create(:item, uniqid: '1000', shop: shop)
      subject

      existing_item.reload
      {
        url: 'http://example.com/item/1000',
        price: 500,
        categories: ['1'],
        image_url: 'http://example.com/item/1000.jpg',
        name: 'Existing item',
        description: 'Existing item description'
      }.each{|attr, value| expect(existing_item.public_send(attr)).to eq(value) }
    end
  end
end
