require 'rails_helper'

describe YmlImporter do
  let!(:shop) { create(:shop) }
  before do
    create(:wear_type_dictionary, type_name: 'trouser', word: 'Шорты')
    allow_any_instance_of(Yml).to receive(:download).and_return(File.open("#{Rails.root}/spec/fixtures/files/yml.xml"))
  end

  subject { YmlImporter.new.perform(shop.id) }

  it 'categories' do
    subject
    expect(ItemCategory.count).to eq(3)
    expect(ItemCategory.find_by(external_id: 2).url).to eq('http://example.com/category1')
  end


  it 'import' do
    subject
    expect(shop.reload.yml_loaded).to be_truthy
    expect(shop.reload.yml_state).to be_nil
    expect(Item.count).to eq(3)

    # Fashion
    item = Item.find_by uniqid: '3613372537448', shop_id: shop.id
    expect(item.leftovers).to eq('one')
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
    expect(item.cosmetic_gender).to eq('f')
    expect(item.cosmetic_nail).to eq(true)
    expect(item.cosmetic_nail_type).to eq('polish')
    expect(item.cosmetic_nail_color).to eq('red')
    expect(item.cosmetic_perfume_family).to eq('woody')
    expect(item.cosmetic_perfume_aroma).to eq('fruity')
    expect(item.cosmetic_periodic).to eq(true)
    expect(item.cosmetic_professional).to eq(true)
    expect(item.shop_recommend).to eq(%w(127101 127802))

    # Realty
    expect(item.is_realty).to be_truthy
    expect(item.realty_type).to eq('living')
    expect(item.realty_action).to eq('rent')
    expect(item.realty_space_min).to eq(30)
    expect(item.realty_space_max).to eq(100)
    expect(item.realty_space_final).to eq(37)

    # Blank
    item = Item.find_by uniqid: '1', shop_id: shop.id
    expect(item.leftovers).to be_nil
    expect(item.present?).to be_truthy
    expect(item.price).to eq(10)
    expect(item.is_available).to be_truthy
    expect(item.name).to eq('Купальные шорты')
    expect(item.description).to eq('')
    expect(item.model).to eq('Купальные шорты Inlay')
    expect(item.seasonality).to be_nil
    expect(item.is_cosmetic).to be_nil
    expect(item.cosmetic_nail).to be_nil
    expect(item.cosmetic_nail_type).to be_nil
    expect(item.cosmetic_nail_color).to be_nil
    expect(item.cosmetic_perfume_aroma).to be_nil
    expect(item.cosmetic_professional).to be_nil

    # Cosmetic
    item = Item.find_by uniqid: '5546328', shop_id: shop.id
    expect(item.leftovers).to be_nil
    expect(item.present?).to be_truthy
    expect(item.is_available).to be_truthy
    expect(item.is_cosmetic).to eq(true)
    expect(item.cosmetic_nail).to eq(true)
    expect(item.cosmetic_nail_type).to be_nil
    expect(item.cosmetic_nail_color).to be_nil
    expect(item.cosmetic_perfume_aroma).to be_nil
    expect(item.cosmetic_periodic).to be_nil
    expect(item.cosmetic_professional).to be_nil
  end
end
