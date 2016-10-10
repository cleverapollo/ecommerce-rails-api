# [Yandex market language](https://yandex.ru/support/partnermarket/yml/about-yml.xml) file SAX parser

```.ruby
require "open-uri"

file = Rees46ML::File.new open("https://yandex.st/market-export/1.0-17/partner/help/YML.xml")

file.lazy # => #<Enumerator::Lazy: #<Rees46ML::File ... >>

file.lazy.each {|element| puts element.class.name }

# => Rees46ML::Offer
# => Rees46ML::Offer
# => Rees46ML::Offer
# => Rees46ML::Offer
# => Rees46ML::Offer
# => Rees46ML::Offer
# => Rees46ML::Offer
# => Rees46ML::Shop

puts file.lazy.select{ |element| element.is_a?(Rees46ML::Offer) }.take(1).map(&:attributes).force

# => {:usupported_elements=>[], :id=>"12341", :name=>"", :type=>nil, :group_id=>"", :market_category=>"", :bid=>"13", :cbid=>"20", :available=>"true", :url=>#<URI::HTTP http://magazin.ru/product_page.asp?pid=14344>, :price=>"15000", :baseprice=>"", :oldprice=>"", :currency_id=>"RUR", :category_id=>"101", :locations=>[], :accessories=>[], :ignored=>false, :pictures=>#<Set: {#<URI::HTTP http://magazin.ru/img/device14344.jpg>}>, :store=>nil, :pickup=>nil, :delivery=>true, :adult=>nil, :ordering_time=>"", :local_delivery_cost=>"300", :delivery_options=>#<Set: {}>, :vendor=>"НP", :sales_notes=>"", :vendor_code=>"Q7533A", :description=>"A4, 64Mb, 600x600 dpi, USB 2.0, 29стр/мин ч/б / 15стр/мин цв, лотки на 100л и 250л, плотность до 175г/м, до 60000 стр/месяц ", :manufacturer_warranty=>true, :country_of_origin=>"Япония", :ages=>#<Set: {}>, :barcodes=>#<Set: {}>, :cpa=>"", :weight=>"", :price_margin=>"", :params=>#<Set: {}>, :type_prefix=>"Принтер", :model=>"Color LaserJet 3000", :author=>"", :publisher=>"", :series=>"", :year=>"", :isbn=>"", :volume=>"", :part=>"", :language=>"", :binding=>"", :page_extent=>"", :downloadable=>"", :performed_by=>"", :performance_type=>"", :storage=>"", :format=>"", :recording_length=>"", :artist=>"", :title=>"", :media=>"", :starring=>"", :director=>"", :original_name=>"", :country=>"", :world_region=>"", :region=>"", :days=>"", :data_tour=>"", :hotel_stars=>"", :room=>"", :meal=>"", :included=>"", :transport=>"", :place=>"", :plan=>"", :hall=>"", :hall_part=>"", :date=>"", :is_premiere=>"", :is_kids=>"", :child=>nil, :fashion=>nil, :cosmetic=>nil}
```


# Решение проблемы типа undefined method `auto=' for #<Rees46ML::Offer:0x007f9acb046218>

Когда добавляете новую секцию отраслевого, может возникать такая ошибка, даже если вы везде прописали секцию в parser.rb и т.д.

Решается так:

В rees46_ml/offer.rb добавить
```attribute :auto, Rees46ML::Auto, lazy: true```

И туда же добавить метод

```
def auto?
  auto.present?
end
```
