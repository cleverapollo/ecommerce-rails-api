require 'rails_helper'

describe YmlWorker do
  describe '#perform' do
    let!(:shop) { create(:shop, yml_file_url: "#{Rails.root}/spec/files/example.xml") }
    let!(:brand_campaign) { create(:brand_campaign, brand: 'Apple', downcase_brand:'apple')}

    let!(:promo_brand) { create(:brand, keyword:'apple') unless Brand.where(keyword:'apple').limit(1)[0]}

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
        barcode: '123456',
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

    it 'gets correct cosmetic attributes' do
      existing_item = create(:item, uniqid: '8000', shop: shop)
      subject

      existing_item.reload
      {
          brand:'3com',
          hypoallergenic:true,
          gender:'m',
          part_type:['hair','body'],
          skin_type:['normal','oily'],
          condition:['colored','damaged'],
          periodic:true,
          volume:[{"price"=>1000, "value"=>200}, {"price"=>2000, "value"=>400}]
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

    context 'gets correct type by' do

      let!(:wear_type_dictionary) do
        create(:wear_type_dictionary, type_name:'shirt', word:'платья')
        create(:wear_type_dictionary, type_name:'shirt', word:'рубашка')
        create(:wear_type_dictionary, type_name:'tshirt', word:'футболка')
        create(:wear_type_dictionary, type_name:'tshirt', word:'майка')
      end

      it 'category' do
        existing_item = create(:item, uniqid: '7000', shop: shop)
        subject

        existing_item.reload
        {
            wear_type: 'shirt'
        }.each{|attr, value| expect(existing_item.public_send(attr)).to eq(value) }
      end

      it 'name' do
        existing_item = create(:item, uniqid: '6000', shop: shop)
        subject

        existing_item.reload
        {
            wear_type: 'tshirt'
        }.each{|attr, value| expect(existing_item.public_send(attr)).to eq(value) }
      end
    end

    describe "exceptions" do
      describe "fail http request" do
        before { allow_any_instance_of(Yml).to receive(:get).and_raise(OpenURI::HTTPError) }

        it { expect{ subject }.to raise_error{ YmlWorker::Error.new("Плохой код ответа.") } }
      end

      describe "invalid archive" do
        before { allow_any_instance_of(Yml).to receive(:get).and_raise(YmlWorker::Error.new("Не обнаружено XML-файла в архиве.")) }

        it { expect{ subject }.to raise_error{ YmlWorker::Error.new("Не обнаружено XML-файла в архиве.") } }
      end

      describe "invalid XML" do
        before { allow_any_instance_of(Yml).to receive(:get).and_raise(Nokogiri::XML::SyntaxError.new("test")) }

        it { expect{ subject }.to raise_error{ YmlWorker::Error.new("Невалидный XML: test.") } }
      end
    end

    describe "integration spec" do
      [
        "http://velogigant.ru/index.php?route=feed/yandex_market",
        "http://funnyfire.ru/export/rees46.xml",
        "https://mezroll.ru/index.php?dispatch=yandex.yml",
        "http://webclim.ru/marketplace/3270.xml",
        "http://xn--80aae3aud0a6b6df.xn--p1ai/marketplace/18382.xml",
        "http://zalmanshop.com.ua/marketplace/19849.xml",
        "http://koleso-kolesikoru.myinsales.ru/marketplace/18650.xml",
        "http://sportov61.ru/market/vm2_market.php",
        "http://ekinder.ru/xml/getxml.php?p=rees46",
        "http://www.pharmacosmetica.ru/getfile/market/rees.yml",
        "http://www.neopod.ru/Neopod.ru/e-services/yandex/ya.xml",
        # "http://www.shmoter.ru/uploads/other/yml_yandex.xml.gz",
        "http://www.bagaboom.ru/marketplace/18976.xml",
        "http://terabytemarket.ru/yamarket.xml?rnd=0.8023088909685612",
        "http://www.tea-philosophy.ru/yandex.yml",
        "http://www.wer.ru/catalog_export/rees46.xml",
        "http://www.natura-line.ru/marketplace/18263.xml",
        # "http://origin2.rbt.ru/export/rees46.xml",
        "http://tigidom.ru/bitrix/catalog_export/yandex_20141112.php",
        "http://xn--48-6kcaaf4exafl.xn--p1ai/vkontakte/yandexmarket/f6192ce6-f75f-432d-9b5c-efdcfd4ca2c4.xml",
        "http://xn--c1ahdpja.xn--p1ai/yandexmarket/6702c850-d421-4ae1-9202-620625f6628a.xml",
        "http://bars.by/yandexmarket/e0c18467-9afa-4187-b93b-00a78956501e.xml",
        "http://www.viofit.ru/xml/yml/",
        "http://arred.ru/yandexmarket/4a1b3a18-f104-4bfb-a130-7056b4b265bf.xml",
        "http://pudra.ru/yandex_market.xml",
        "http://armprodukt.ru/bitrix/catalog_export/yandex.php",
        "http://sredstvo-ot-komarov.ru/index.php?route=feed/yandex_yml",
        "http://svetzavod.ru/market_all.yml",
        "http://kolgotoff.ru/marketplace/21421.xml",
        "http://bymag.ru/yandexmarket/66e50d04-6985-4897-bd8e-53d8c7a3b73d.xml",
        "http://www.kranvam.ru/marketplace/20984.xml",
        "http://myline.com.ua/index.php?route=feed/yandex_yml",
        "http://tv-shoptv.vast.ru/domaincatalogtoxml",
        "http://santehnika-na-zakaz.ru/bitrix/catalog_export/yandex_snz.php",
        "http://www.autocomp.ru/marketplace/16915.xml",
        "http://mazki.com/yamarket.xml",
        "http://www.uniti96.ru/userFiles/export/yandex_export.yml",
        "http://tea-coffee.org/yandexmarket/9e62e20f-ef62-459f-8c4f-729c716420e5.xml",
        "http://mebelell.ru/bitrix/catalog_export/yandex_723895.php",
        "http://www.mir-sumok.ru/yandexmarket/62f44021-f58b-449b-b469-c540eacc5029.xml",
        # "http://baza-shop.ru/products/share/rproducts.yml",
        "http://servis.tom.ru/yandexmarket/023b847c-fc31-425f-8927-be0455d30d6c.xml",
        "http://italianadom.ru/marketplace/12103.xml",
        "http://venezia-shoes.by/products.xml",
        "http://oreshki.com.ua/marketplace/3291.xml",
        "http://filtorg.ru/ymlsitemapnoad.xml",
        "http://www.trendsbrands.ru/upload/export/retailrocket.xml",
        "http://av-aks.ru/var/files/YML/1_yandex_market.yml",
        "http://www.piter.com/marketplace/12303.xml",
        "http://city-boom.ru/yamarket.xml",
        "http://www.alfa-shopping.ru/marketplace/21183.xml",
        "http://tmp.netcat/netcat/modules/netshop/export/yandex/bundle1.xml",
        "http://beta50.on-advantshop.net/beta_65697_izxeruunnj/yamarket.xml",
        "http://in-trend.club/marketplace/21972.xml",
        "http://kumiho.club/market/novye/yml/",
        "http://www.only-rayban.ru/collection/zhenskaya",
      ].uniq.each do |url|
        it url, skip: !ENV["INTEGRATION_SPEC"].present? do
          expect {
            shop = create(:shop, yml_file_url: url)
            YmlWorker.new.perform(shop.id)
          }.to_not raise_error
        end
      end

    end
  end
end
