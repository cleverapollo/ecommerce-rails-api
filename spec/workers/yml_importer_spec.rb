require 'rails_helper'

describe YmlImporter do
  let!(:shop) { create(:shop) }
  before do
    create(:wear_type_dictionary, type_name: 'trouser', word: 'Шорты')
    allow_any_instance_of(Yml).to receive(:download).and_return(File.open("#{Rails.root}/spec/fixtures/files/yml.xml"))
  end

  subject { YmlImporter.new.perform(shop.id) }

  it 'import' do
    subject
    expect(shop.reload.yml_loaded).to be_truthy
    expect(shop.reload.yml_state).to be_nil
    expect(Item.count).to eq(2)
    expect(ItemCategory.count).to eq(3)

    # Fashion
    item = Item.find_by uniqid: '3613372537448', shop_id: shop.id
    expect(item.present?).to be_truthy
    expect(item.price).to eq(4290)
    expect(item.is_available).to be_truthy
    expect(item.name).to eq('Купальные шорты Inlay 17"')
    expect(item.description).to eq('Купальные шорты Inlay 17" классика')
    expect(item.url).to eq('http://www.quiksilver.ru/3613372537448.html')
    expect(item.image_url).to eq('http://static.quiksilver.com/www/store.quiksilver.eu/html/images/catalogs/global/quiksilver-products/all/default/large/eqyjv03198_inlayvolley17,w_bjb6_frt1.jpg')
    expect(item.widgetable).to eq(true)
    expect(item.brand).to eq('quiksilver')
    expect(item.ignored).to eq(false)
    expect(item.type_prefix).to eq('Бордшорты')
    expect(item.vendor_code).to eq('EQYJV03198')
    expect(item.model).to eq('Купальные шорты Inlay 17" model')
    expect(item.is_fashion).to eq(true)
    expect(item.fashion_gender).to eq('m')
    expect(item.fashion_feature).to eq('adult')
    expect(item.fashion_sizes).to eq(%w(46 48 50 54 56))
    expect(item.fashion_wear_type).to eq('trouser')
    expect(item.category_ids).to eq(%w(8 13))
    expect(item.seasonality).to eq([1, 3, 4, 6])

    # Blank
    item = Item.find_by uniqid: '1', shop_id: shop.id
    expect(item.present?).to be_truthy
    expect(item.price).to eq(10)
    expect(item.is_available).to be_truthy
    expect(item.name).to eq('Купальные шорты')
    expect(item.description).to eq('')
    expect(item.model).to eq('Купальные шорты Inlay')
    expect(item.seasonality).to be_nil
  end
end
