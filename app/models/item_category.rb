##
# Категория товара.
#
class ItemCategory < ActiveRecord::Base

  belongs_to :shop

  validates :shop_id, presence: true
  validates :external_id, presence: true

  has_many :brand_campaign_item_categories
  has_many :item_categories, through: :brand_campaign_item_categories

  scope :without_taxonomy, -> { where('taxonomy is null') }
  scope :with_taxonomy, -> { where('taxonomy is not null') }
  scope :for_taxonomy_definition, -> { where('taxonomy is not null and name is not null') }

  TAXONOMY_KEYWORDS = {

      'kids.toys' => ['игрушк'],
      'kids.dolls' => ['куклы', 'кукла'],
      'kids.skates' => ['скейт', 'самокат'],
      'kids.carriage' => ['коляск'],
      'kids.swing' => ['качели'],
      'kids.bottles' => ['бутылочк'],
      'kids.fmcg.diapers' => ['подгузник'],

      'pets' => [],

      'apparel.shoes' => ['ботинк', 'туфл', 'сапог', 'сандали', 'тапочк'],
      'apparel.trousers' => ['брюки', 'штаны', 'колготк'],
      'apparel.belt' => ['ремни', 'ремень'],
      'apparel.blazer' => ['блейзер'],
      'apparel.glove' => ['перчатк'],
      'apparel.hat' => ['шапк', 'шляп', 'шапочк'],
      'apparel.jacket' => ['пиджак'],
      'apparel.costume' => ['костюм'],
      'apparel.shirt' => ['рубашк', 'пуловер', 'толстовк'],
      'apparel.sock' => ['носки'],
      'apparel.tshirt' => ['футболк'],
      'apparel.underwear' => ['трусы', 'бюстгал', 'нижнее белье'],

      'appliances.kitchen.refrigerators' => ['холодильник', 'морозильн'],
      'appliances.kitchen.washer' => ['стиральн'],
      'appliances.kitchen.dishwasher' => ['посудомоечн'],
      'appliances.kitchen.blender' => ['блендер'],
      'appliances.kitchen.coffee_machine' => ['кофевар'],
      'appliances.kitchen.coffee_grinder' => ['кофемолк'],
      'appliances.kitchen.microwave' => ['микроволн'],
      'appliances.kitchen.mixer' => ['миксер'],
      'appliances.kitchen.toster' => ['тостер'],
      'appliances.kitchen.steam_cooker' => ['пароварк'],
      'appliances.kitchen.kettle' => ['чайник', 'термопот'],
      'appliances.kitchen.hood' => ['вытяжки', 'вытяжка'],
      'appliances.kitchen.hob' => ['варочная поверхность', 'варочные поверхности', 'газовые плиты', 'электроплиты'],
      'appliances.kitchen.juicer' => ['соковыжималк'],
      'appliances.kitchen.wine_cabinet' => ['винные шкафы'],
      'appliances.kitchen.meat_grinder' => ['мясорубк'],
      'appliances.kitchen.grill' => ['гриль', 'грили'],
      'appliances.kitchen.fryer' => ['фритюрниц'],
      'appliances.kitchen.oven' => ['духовк', 'духовые шкафы'],
      'appliances.environment.vacuum' => ['пылесос'],
      'appliances.environment.air_conditioner' => ['кондиционер', 'сплит-систем'],
      'appliances.environment.climate' => ['климатическ'],
      'appliances.environment.air_heater' => ['конвектор', 'тепловентилят', 'обогревател'],
      'appliances.environment.air_cleaner' => ['очистители воздуха'],
      'appliances.environment.water_heater' => ['водонагревател', 'бойлер'],
      'appliances.environment.fan' => ['вентилятор'],
      'appliances.iron' => ['утюг'],
      'appliances.ironing_board' => ['гладильн'],
      'appliances.steam_cleaner' => ['пароочистител'],
      'appliances.personal.epilator' => ['эпиллятор'],
      'appliances.personal.hair_cutter' => ['стрижк'],
      'appliances.personal.scales' => ['весы'],
      'appliances.personal.massager' => ['массажер'],
      'appliances.sewing_machine' => ['швейные машины'],

      'stationery.paper' => ['бумага'],
      'stationery.cartrige' => ['картридж'],
      'stationery.stapler' => ['степлер'],
      'stationery.battery' => ['батарейк'],

      'electronics.camera.photo' => ['canon', 'nikon', 'pentax', 'объектив', 'бленда'],
      'electronics.camera.video' => ['видеокамер'],
      'electronics.video.projector' => ['проектор', 'проекцион'],
      'electronics.video.tv' => ['телевизор', 'кинотеатр'],
      'electronics.audio.acoustic' => ['акустик', 'акустичес'],
      'electronics.audio.dictaphone' => ['диктофон'],
      'electronics.audio.music_tools.piano' => ['синтезатор', 'midi'],
      'electronics.audio.headphone' => ['наушник'],
      'electronics.audio.subwoofer' => ['сабвуфер'],
      'electronics.audio.microphone' => ['микрофон'],
      'electronics.calculator' => ['калькулятор'],
      'electronics.clocks' => ['часы'],
      'electronics.smartphone' => ['смартфон'],
      'electronics.telephone' => ['телефон'],
      'electronics.fax' => ['факсы'],
      'electronics.tablet' => ['планшет'],
      'electronics.ip_telephony' => ['IP телефония'],

      'computers.desktop' => ['компьютер', 'моноблок', 'неттоп'],
      'computers.notebook' => ['ноутбук', 'ультрабук'],
      'computers.gaming' => ['игровая консоль', 'игровые консоли', 'playstation', 'x-box', 'psp'],
      'computers.ebooks' => ['электронные книги'],
      'computers.components.hdd' => ['жесткие диски', 'жесткий диск', 'hdd', 'ssd', 'scsi'],
      'computers.components.cooler' => ['кулер'],
      'computers.components.sound_card' => ['звуковые карты'],
      'computers.components.videocards' => ['видеокарт'],
      'computers.components.cpu' => ['процессор', 'cpu'],
      'computers.components.tv_tuner' => ['tv-тюнер'],
      'computers.components.memory' => ['ram', 'оперативная память'],
      'computers.components.motherboard' => ['материнские платы'],
      'computers.components.power_supply' => ['блоки питания'],
      'computers.components.3d_glasses' => ['3D-очки'],
      'computers.components.network_adapter' => ['сетевые адаптеры', 'сетевые карты'],
      'computers.peripherals.mouse' => ['мыши'],
      'computers.peripherals.monitor' => ['монитор'],
      'computers.peripherals.keyboard' => ['клавиатур'],
      'computers.peripherals.printer' => ['принтер', 'мфу', 'плоттер'],
      'computers.peripherals.camera' => ['веб-камер'],
      'computers.peripherals.scanner' => ['сканер'],
      'computers.peripherals.wifi' => ['точки доступа', 'wi-fi'],
      'computers.peripherals.nas' => ['сетевые накопители'],
      'computers.peripherals.joystick' => ['джойстик'],
      'computers.peripherals.copier' => ['копировальн'],
      'computers.network.router' => ['маршрутизатор', 'роутер'],
      'computers.software.operating_system' => ['операционные системы'],
      'computers.software.office' => ['офисные приложения'],
      'computers.software.accounting' => ['бухгалтерские приложения'],
      'computers.server' => ['сервер'],

      'cosmetic' => [],

      'construction.tools.drill' => ['дрель', 'дрели', 'сверл', 'перфоратор'],
      'construction.tools.saw' => ['пила', 'пилы'],
      'construction.tools.pump' => ['насос'],
      'construction.tools.welding' => ['сварочн', 'сварк'],
      'construction.tools.generator' => ['генератор'],
      'construction.tools.soldering' => ['паяльник'],
      'construction.tools.heater' => ['тепловые пушки', 'тепловая пушка'],
      'construction.tools.wrench' => ['гайковерт'],
      'construction.tools.screw' => ['отверт'],
      'construction.tools.axe' => ['топор'],
      'construction.tools.light' => ['светильник', 'прожектор'],
      'construction.tools.painting' => ['краскопульт'],
      'construction.components.faucet' => ['смесители', 'водопроводные краны'],

      'country_yard.cultivator' => ['культиватор'],
      'country_yard.lawn_mower' => ['газонокосил', 'мотокос'],
      'country_yard.watering' => ['полив'],
      'country_yard.weather_stantion' => ['метеостанци'],

      'furniture.living_room.sofa' => ['диван', 'тахта'],
      'furniture.living_room.cabinet' => ['шкаф'],
      'furniture.bedroom.bed' => ['кроват'],
      'furniture.kitchen.table' => ['столы'],
      'furniture.kitchen.chair' => ['стул'],
      'furniture.bathroom.bath' => ['ванны', 'ванна'],
      'furniture.bathroom.toilet' => ['унитаз', 'биде'],

      'auto.accessories.videoregister' => ['видеорегистратор', 'видео-регистратор', 'видео регистратор'],
      'auto.accessories.immobilizer' => ['иммобилайзер'],
      'auto.accessories.acoustic' => ['автоакустика'],
      'auto.accessories.radar' => ['радар-детектор'],
      'auto.accessories.player' => ['магнитол'],
      'auto.accessories.parktronic' => ['парктроник'],
      'auto.accessories.window' => ['стеклоподъемник'],
      'auto.accessories.compressor' => ['компрессор'],
      'auto.accessories.antifog_light' => ['противотуман'],
      'auto.accessories.anti_freeze' => ['антифриз'],
      'auto.accessories.light' => ['фары', 'подсветк', 'автосвет'],
      'auto.accessories.winch' => ['лебедк'],
      'auto.accessories.seat' => ['автокресл'],
      'auto.accessories.wheel' => ['покрышк'],
      'auto.accessories.alarm' => ['автосигнализац'],
      'auto.accessories.gps' => ['gps-навигатор'],

      'banking.equipment' => ['банковское оборудование', 'счетчики банкнот'],

      'medicine.tools.tonometer' => ['тонометр'],

      'sport.bicycle' => ['велосипед'],
      'sport.trainer' => ['тренаж'],
      'sport.tennis' => ['теннис'],
      'sport.snowboard' => ['сноуборд'],
      'sport.ski' => ['лыжи', 'лыжны'],
      'sport.diving' => ['ласты'],

  }

  def self.bulk_update(shop_id, categories_tree)
    transaction do
      categories_tree.each do |yml_category|
        category = where(shop_id: shop_id, external_id: yml_category.id).first_or_create

        if yml_category.parent_id.present?
          yml_parent_category = categories_tree[yml_category.parent_id]

          parent_category = where(shop_id: shop_id, external_id: yml_parent_category.try(:id)).first_or_create

          category.update! parent_id: parent_category.id,
                           external_id: yml_category.id,
                           parent_external_id: yml_category.parent_id,
                           name: yml_category.name
        else
          category.update! parent_id: nil,
                           external_id: yml_category.id,
                           parent_external_id: nil,
                           name: yml_category.name
        end
      end
    end
  end


  def self.process_taxonomies
    Shop.active.find_each do |shop|
      shop.item_categories.without_taxonomy.find_each do |item_category|
        item_category.define_taxonomy!
      end
    end
  end

  def define_taxonomy!
    if _taxonomy = find_taxonomy
      update taxonomy: _taxonomy
    end
  end


  private

  def find_taxonomy

    TAXONOMY_KEYWORDS.each do |k, keywords|
      keywords.each do |word|
        return k if word.strip.present? && name.mb_chars.downcase.scan(word.strip).any?
      end
    end

    nil

  end




end
