REES46 API
----------

![Codeship](https://www.codeship.io/projects/d543d470-be61-0131-e6b6-6ea1a21f61c4/status)

Back-end для приема событий и выдачи рекомендаций
=================================================

### Описание
Ядро REES46. Содержит в себе все алгоритмы расчета рекомендаций.

Делится на три основные части:

0. Инициализация пользователя

1. Прием событий. Из различных источников (JS, модули, SDK) к нам приходят данные о действиях пользователей в магазинах. Эти данные нужно обработать и сохранить.

2. Выдача рекомендаций. Для пользователей запрашиваются рекомендации по различным сценариям. Тут в дело вступает Apache Mahout.

3. Импорты. Заказы, товары, yandex market file.

### Внешние зависимости
* ruby-2.3.0
* PostgreSQL 9.5+
* Redis
* https://bitbucket.org/mkechinov/rees46_brb

### Развертывание на development

```
$ bundle
... $ bin/rake db:create db:schema:load ... не делать schema:load на production, т.к. она не создает функции, генерирующие уникальные ID. Использовать восстановление бэкапа.
$ foreman start
```

### Специфичные файлы конфигурации

/config/application.yml - прописать переменную REES46_SHARD (двузначный номер - 00, 01, ...)
/config/secrets – прописать весь набор ключей, указанный в примере secrets.yml.example
/config/database.yml – прописать доступ к мастер-базе (базе, где содержатся клиенты сервиса, магазины и т.д.

### Тесты

```sh
RAILS_ENV=test bundle exec rake db:reset
RAILS_ENV=test bundle exec rake db:test:load_schema
rspec
```
or
```sh
bin/testing
```
### Ручное импортирование YML файла

```
YmlImporter.new.perform(Shop.last.id)
# Downloaded : 9.6 MB => nil
```

Если не возникло исключений, то файл успешно импортирован.

### Мониторинг Sidekiq

Запуск на сервере:
```
RAILS_ENV=production bundle exec rackup sidekiq.ru -E production -p 8080 -o 5.9.48.142
```

### Принцип работы Rees46ML

В gem-е используется SAX парсер, он принципиально отличается от DOM парсеров, вместо предоставления обьектной модели, как например обьектная модель DOM браузера, он просто "бежит" по файлу и говорит: "началась такая-то нода, закончилась такая-то нода, начался текст, встретился комментарий".
Вся суть в имплемментации SAX парсера – реагировать на эти события.

Мы используем [Nokogiri::XML::SAX::Document](http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/SAX/Parser), он имеет несколько событий:

- `start_element(name, attrs = [])`
- `end_element(name)`
- `attr(name, value)`
- `text(string)`
- `cdata(string)`

Пример:

```.ruby
class Test < Nokogiri::XML::SAX::Document
  def path
    @path ||= []
  end

  def start_element(name, attributes = [])
    puts (" " * path.size) << "< start #{ name } : #{ attributes.inspect }"
    path << name
  end

  def end_element(name)
    puts (" " * path.size) << "> finish " << name
    path.pop
  end
end

xml = <<-XML
<test a="1" b="2">
  <element>1</element>
  <element>2</element>
</test>
XML

parser = Nokogiri::XML::SAX::Parser.new(Test.new)

parser.parse(xml)

#=>

< start test : [["a", "1"], ["b", "2"]]
 < start element : []
  > finish element
 < start element : []
  > finish element
 > finish test

```

Данный пример показывает последовательность событий, на которые реагируется наш обработчик.
То есть всё просто - получили событие с данными -> среагировали на него.

Далее, для обьектной модель элементов XML испольлзуется [VIRTUS](https://github.com/solnic/virtus).
Он удобен для создание моделей, даёт дополнительные возможности для нормализации/конвертации данных во время инициализации модели.

Пример:

```
class User
  include Virtus.model

  attribute :name, String
  attribute :age, Integer
  attribute :birthday, DateTime
end

user = User.new(:name => 'Piotr', :age => "31")
user.attributes # => { :name => "Piotr", :age => 31 }

user.name # => "Piotr"

user.age = '31' # => 31
user.age.class # => Fixnum

user.birthday = 'November 18th, 1983' # => #<DateTime: 1983-11-18T00:00:00+00:00 (4891313/2,0/1,2299161)>
```

Так же `virtus` позволяет писать свои типы атрибутов и прочее.
Конкретно мы используем его для [нормализации url вот так](https://github.com/postrank-labs/postrank-uri):

```
module Rees46ML
  class Offer
    attribute :url, Rees46ML::URL
  end

  class URL < Virtus::Attribute
    def coerce(value)
      URI.parse PostRank::URI.clean(value.to_s)
    end
  end
end

Rees46ML::Offer.new(url: "http://example.com?utm_source%3Danalytics").url => "http://example.com/"
```

Каждый элемент XML оборачивается в обьект, например:

```
<currency id="RUB" rate="1"/>
```

превращается в:

```
Rees46ML::Currency.new(id: "RUB", rate: "1")
```

или

```
<offer id="12343" type="audiobook" bid="17" available="true">
  <url>http://magazin.ru/product_page.asp?pid=14346</url>
  <price>200</price>
  <currencyId>RUR</currencyId>
  <categoryId type="Own">14</categoryId>
</offer>
```
превращается в

```
Rees46ML::Offer.new(id: "RUB", type: "audiobook", bid: "17" available: "true", price: 200 ...)
```

и так далее.

То есть мы имеем `SAX` обработчик, который реагирует на события и оборачиваем каждый элемент XML в обьект.
Правильно реагировать на события, которые ничем не ограничены (ничто не мешает пользователю прислать мусор в XML), давольно "неудобно", поэтому в парсере используется [AASM](https://github.com/aasm/aasm).
Данный гем реализует паттерн [конечный автомат](https://ru.wikipedia.org/wiki/%D0%9A%D0%BE%D0%BD%D0%B5%D1%87%D0%BD%D1%8B%D0%B9_%D0%B0%D0%B2%D1%82%D0%BE%D0%BC%D0%B0%D1%82),то есть нам, при написании парсера нужно только описать состояния автомата и события, на которые он может реагировать.

В данном случае состоями у нас являются названия элементов : `offer`, `url`, `price`, `currencyId`, `categoryId` и так далее, а событиями : `start_offer`, `end_offer`, `start_url`, `end_url` и так далее.
Кол-во состояний и событий напрямую зависит от схемы XML, то есть чем проще XML, тем проще конечный автомат, тем проще парсер в целом.
На каждое событие реагируем по-разному, при `start_offer` инициализируем модель `Rees46ML::Offer`, при встречающихся атрибутах в XML выставляем их значения в атрибутах модели, при `end_offer` отдаём модель. Если внутри offer нам встречается другой вложенный XML элемент, то откладываем offer в сторону (кладём на стек), работаем с новым элементом, новой моделью, а когда текущий элемент закончен, возвращаемся к `offer`.

То есть, мы имеем парсер, который способен отдавать нам элементы XML в виде обьектов, которые автоматически `cast` - уют атрибуты модели в нужные нам типы данных. Для удобства работы с этим "потоком" элементов, всё это оборачивается в [Lazy enumerator](http://ruby-doc.org/core-2.2.0/Enumerator.html).

В итоге интерфейс обхода XML выглядит вот так:

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

То есть мы получаем коллекцию `ruby` обьектов, с которыми удобно работать.

Важно: так как при парсинге идёт активная работа с диском, то для оптимизации операция парсинга оборачивается в [fiber](http://ruby-doc.org/core-2.2.0/Fiber.html), это улучшает/облегчает работу планировщика OS.

Послезные ссылки:

- [SAX vs DOM](https://www.reddit.com/r/ruby/comments/12b25u/benchmark_ox_vs_nokogiri_and_sax_vs_dom_parsing/)
- [Ruby 2.0 Works Hard So You Can Be Lazy](http://patshaughnessy.net/2013/4/3/ruby-2-0-works-hard-so-you-can-be-lazy)
- [Fibers & Cooperative Scheduling](https://www.igvita.com/2009/05/13/fibers-cooperative-scheduling-in-ruby/)



