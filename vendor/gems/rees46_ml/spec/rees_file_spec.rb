require 'spec_helper'
describe "check rees.xml" do
  let(:path) { File.expand_path("files/rees.xml", File.dirname(__FILE__)) }
  let(:file) { Rees46ML::File.new open(path) }

  specify "shop elements" do
    file.lazy.select{ |element| element.is_a?(Rees46ML::Shop) }.each do |shop|
      expect(shop.name).to eq("Магазин укрепления семьи")
      expect(shop.company).to eq("example.com")
      expect(shop.url).to eq("http://example.com/")
      expect(shop.local_delivery_cost).to eq("200")
      expect(shop.phone).to be_empty
      expect(shop.platform).to eq("CMS")
      expect(shop.version).to eq("2.3")
      expect(shop.agency).to eq("Agency")
      expect(shop.email).to eq("CMS@CMS.ru")
      expect(shop.store).to eq(true)
      expect(shop.pickup).to eq(false)
      expect(shop.delivery).to eq(false)
      expect(shop.adult).to eq(true)
      expect(shop.cpa).to eq("0")

      expect(shop.delivery_options.size).to eq(3)
      expect(shop.delivery_options).to include(Rees46ML::DeliveryOption.new(cost: 300, days: "1"))
      expect(shop.delivery_options).to include(Rees46ML::DeliveryOption.new(cost: 300, days: "1-3"))
      expect(shop.delivery_options).to include(Rees46ML::DeliveryOption.new(cost: 100, days: "1", order_before: "14"))

      expect(shop.currencies.size).to eq(3)
      expect(shop.currencies).to include(Rees46ML::Currency.new(id: "RUB", rate: "1"))
      expect(shop.currencies).to include(Rees46ML::Currency.new(id: "EUR", rate: "75.05"))
      expect(shop.currencies).to include(Rees46ML::Currency.new(id: "USD", rate: "66.48"))

      expect(shop.categories.size).to eq(5)
      expect(shop.categories).to include(Rees46ML::Category.new(id: "4", name: "Категория 4", parentId: "3"))
      expect(shop.categories).to include(Rees46ML::Category.new(id: "3", name: "Категория 3", parentId: "2"))
      expect(shop.categories).to include(Rees46ML::Category.new(id: "2", name: "Категория 2", parentId: "1"))
      expect(shop.categories).to include(Rees46ML::Category.new(id: "1", name: "Категория 1", parentId: "0"))
      expect(shop.categories).to include(Rees46ML::Category.new(id: "0", name: "Корень категорий"))
    end
  end

  specify "offers" do
    offer = file.lazy.detect{ |element| element.is_a?(Rees46ML::Offer) }
    expect(offer.id).to eq(1)
    expect(offer.name).to eq("Наручные часы Casio A1234567B")
    expect(offer.type).to eq("vendor.model")
    expect(offer.group_id).to eq("10")
    expect(offer.market_category).to be_empty
    expect(offer.bid).to eq(21)
    expect(offer.cbid).to eq(43)
    expect(offer.available).to eq(true)
    expect(offer.url).to eq("http://www.example.com/catalog/show/KID/1")
    expect(offer.price).to eq("100")
    expect(offer.oldprice).to eq("500")
    expect(offer.currency_id).to eq("RUR")
    expect(offer.category_id).to eq("1")
    expect(offer.ignored).to eq(false)
    expect(offer.pickup).to eq(false)
    expect(offer.store).to eq(false)
    expect(offer.delivery).to eq(true)
    expect(offer.adult).to eq(false)
    expect(offer.local_delivery_cost).to eq("1300")
    expect(offer.vendor).to eq("Clementoni")
    expect(offer.sales_notes).to eq("-5% на все товары при регистрации на сайте.")
    expect(offer.vendor_code).to eq("CH366C")
    expect(offer.description).to eq("Cупер дупер оберег для вашей собаки")
    expect(offer.manufacturer_warranty).to eq(true)
    expect(offer.country_of_origin).to eq("Китай")
    expect(offer.cpa).to eq("1")
    expect(offer.weight).to eq("2.07")
    expect(offer.type_prefix).to eq("Компьютер")
    expect(offer.model).to eq("Электронная погремушка Обезьянка для вашего мужа")
    expect(offer.author).to eq("Александра Маринина")
    expect(offer.publisher).to eq("Эксмо")
    expect(offer.series).to eq("А. Маринина — королева детектива")
    expect(offer.year).to eq("2007")
    expect(offer.isbn).to eq("978-5-699-23647-3")
    expect(offer.volume).to eq("2")
    expect(offer.part).to eq("1")
    expect(offer.language).to eq("rus")
    expect(offer.binding).to eq("70x90/32")
    expect(offer.page_extent).to eq("288")
    expect(offer.downloadable).to eq(false)
    expect(offer.performed_by).to eq("Николай Фоменко")
    expect(offer.performance_type).to eq("начитана")
    expect(offer.storage).to eq("CD")
    expect(offer.format).to eq("mp3")
    expect(offer.recording_length).to eq("10.33")
    expect(offer.artist).to eq("Pink Floyd")
    expect(offer.title).to eq("Dark Side Of The Moon, Platinum Disc")
    expect(offer.media).to eq("CD")
    expect(offer.starring).to eq("Тони Колетт (Toni Collette), Рэйчел Грифитс (Rachel Griffiths)")
    expect(offer.director).to eq("П Дж Хоген")
    expect(offer.original_name).to eq("Muriel's wedding")
    expect(offer.country).to eq("Австралия")
    expect(offer.world_region).to eq("Африка")
    expect(offer.region).to eq("Хургада")
    expect(offer.days).to eq("7")
    expect(offer.hotel_stars).to eq("5*****")
    expect(offer.room).to eq("SNG")
    expect(offer.meal).to eq("ALL")
    expect(offer.included).to eq("авиаперелет, трансфер, проживание, питание, страховка")
    expect(offer.transport).to eq("Авиа")
    expect(offer.place).to eq("Московский  международный Дом музыки")
    expect(offer.hall).to eq("Большой зал")
    expect(offer.hall_part).to eq("Партер р. 1-5")
    expect(offer.date).to eq("2012-02-25 12:03:14")
    expect(offer.is_premiere).to eq(false)
    expect(offer.is_kids).to eq(false)

    expect(offer.child.age.min).to eq("0.25")
    expect(offer.child.age.max).to eq("1")
    expect(offer.child.brand).to eq("Clementoni")
    expect(offer.child.gender.value).to eq("u")
    expect(offer.child.type).to eq("hygiene")
    expect(offer.child.gender.value).to eq("u")
    expect(offer.child.hypoallergenic).to eq(true)
    expect(offer.child.periodic).to eq(false)

    expect(offer.child.sizes).to include(Rees46ML::Size.new(value: "XL"))
    expect(offer.child.sizes).to include(Rees46ML::Size.new(value: "S"))
    expect(offer.child.sizes).to include(Rees46ML::Size.new(value: "M"))
    expect(offer.child.sizes).to include(Rees46ML::Size.new(value: "48"))

    expect(offer.child.part_types).to include(Rees46ML::PartType.new(value: "hair"))
    expect(offer.child.part_types).to include(Rees46ML::PartType.new(value: "body"))

    expect(offer.child.skin_types).to include(Rees46ML::SkinType.new(value: "normal"))
    expect(offer.child.skin_types).to include(Rees46ML::SkinType.new(value: "oily"))

    expect(offer.child.conditions).to include("colored")
    expect(offer.child.conditions).to include("damaged")

    expect(offer.fashion.brand).to eq("Gucci")
    expect(offer.fashion.type).to eq("shirt")
    expect(offer.fashion.feature).to eq("adult")
    expect(offer.fashion.gender.value).to eq("f")
    expect(offer.fashion.sizes.count).to eq(4)

    expect(offer.fashion.sizes).to include(Rees46ML::Size.new(value: "XL"))
    expect(offer.fashion.sizes).to include(Rees46ML::Size.new(value: "S"))
    expect(offer.fashion.sizes).to include(Rees46ML::Size.new(value: "M"))
    expect(offer.fashion.sizes).to include(Rees46ML::Size.new(value: "48"))

    expect(offer.delivery_options.size).to eq(3)
    expect(offer.delivery_options).to include(Rees46ML::DeliveryOption.new(cost: 1300, days: "2"))
    expect(offer.delivery_options).to include(Rees46ML::DeliveryOption.new(cost: 1300, days: "2-3"))
    expect(offer.delivery_options).to include(Rees46ML::DeliveryOption.new(cost: 1100, days: "3", order_before: "4"))

    expect(offer.accessories.size).to eq(4)
    expect(offer.accessories).to include(Rees46ML::Accessory.new(id: 5574))
    expect(offer.accessories).to include(Rees46ML::Accessory.new(id: 131))
    expect(offer.accessories).to include(Rees46ML::Accessory.new(id: 99444))
    expect(offer.accessories).to include(Rees46ML::Accessory.new(id: 334411))

    expect(offer.params.size).to eq(7)
    expect(offer.params).to include(Rees46ML::Param.new(name: "Ширина", unit: 'мм', value: "170"))
    expect(offer.params).to include(Rees46ML::Param.new(name: "Глубина", unit: 'мм', value: "180"))
    expect(offer.params).to include(Rees46ML::Param.new(name: "Высота", unit: 'мм', value: "50"))
    expect(offer.params).to include(Rees46ML::Param.new(name: "Вес", unit: 'г', value: "230"))
    expect(offer.params).to include(Rees46ML::Param.new(name: "Возраст от", unit: 'месяцев', value: "3"))
    expect(offer.params).to include(Rees46ML::Param.new(name: "Возраст до", unit: 'месяцев', value: "12"))
    expect(offer.params).to include(Rees46ML::Param.new(name: "Пол", value: "Унисекс"))

    expect(offer.barcodes.size).to eq(2)
    expect(offer.barcodes).to include("4719512011041")
    expect(offer.barcodes).to include("884102000539")

    expect(offer.pictures.size).to eq(2)
    expect(offer.pictures).to include("http://example.com/image/1.jpg")
    expect(offer.pictures).to include("http://example.com/image/1.1.jpg")

    expect(offer.locations.size).to eq(3)
    expect(offer.locations).to include(Rees46ML::Location.new(id: 1, prices: Set.new([Rees46ML::Price.new(value: "50300")])))
    expect(offer.locations).to include(Rees46ML::Location.new(id: 3, prices: Set.new([])))
    expect(offer.locations).to include(Rees46ML::Location.new(id: 4, prices: Set.new([Rees46ML::Price.new(value: "49000")])))

    expect(offer.data_tours.size).to eq(2)
    expect(offer.data_tours).to include("2012-01-01 12:00:00")
    expect(offer.data_tours).to include("2012-01-08 12:00:00")

    expect(offer.ages.size).to eq(3)
    expect(offer.ages).to include(Rees46ML::Age.new(value: "0",unit: "month"))
    expect(offer.ages).to include(Rees46ML::Age.new(value: "12",unit: "month"))
    expect(offer.ages).to include(Rees46ML::Age.new(value: "18",unit: "year"))
  end
end
