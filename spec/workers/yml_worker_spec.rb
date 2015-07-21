require 'rails_helper'

describe YmlWorker do
  describe '#perform' do
    let!(:shop) { create(:shop) }
    let!(:promotion) { create(:advertiser, downcase_brand:'apple')}

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
        categories: ['1', '2', '3'],
        image_url: 'http://example.com/item/2000.jpg',
        name: 'New item',
        description: 'New item description',
        locations: { '1' =>{ 'price' => 550.0 }, '2' => { } },
        brand: 'gucci',
        type_prefix: 'Смартфон',
        vendor_code: 'APPL',
        model: 'iPhone 6 128Gb',
        gender: 'f',
        wear_type: 'blazer',
        sizes: ['40','38','44'],

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
        description: 'Existing item description',
        locations: { '1' =>{ 'price' => 550.0 }, '2' => { } },
        brand: 'apple',
        gender: 'f'
      }.each{|attr, value| expect(existing_item.public_send(attr)).to eq(value) }
    end


    it 'gets correct brand from name' do
      existing_item = create(:item, uniqid: '3000', shop: shop)
      subject

      existing_item.reload
      {
          brand: 'apple',
      }.each{|attr, value| expect(existing_item.public_send(attr)).to eq(value) }
    end

    it 'gets correct name from typePrefix, vendor, model & correct age' do
      existing_item = create(:item, uniqid: '4000', shop: shop)
      subject

      existing_item.reload
      {
          name: 'Smart Apple iPhone 6 128Gb',
          age_min: 0.25,
          age_max: 1.25,
      }.each{|attr, value| expect(existing_item.public_send(attr)).to eq(value) }
    end

    it 'gets correct name from model' do
      existing_item = create(:item, uniqid: '5000', shop: shop)
      subject

      existing_item.reload
      {
          name: 'iPhone 6 128Gb'
      }.each{|attr, value| expect(existing_item.public_send(attr)).to eq(value) }
    end

    it 'disables items that are absent in YMl' do
      absent_item = create(:item, shop: shop, uniqid: 'absent')

      expect{ subject } .to change{ absent_item.reload.is_available }.from(true).to(false)
    end
  end
end
