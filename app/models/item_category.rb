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

      'kids' => [],

      'pets' => [],

      'apparel.shoes' => ['ботинк', 'туфл', 'сапог', 'сандали', 'тапочк'],
      'apparel.trousers' => ['брюки', 'штаны', 'колготк'],
      'apparel.belt' => ['ремни', 'ремень'],
      'apparel.blazer' => ['блейзер'],
      'apparel.glove' => ['перчатк'],
      'apparel.hat' => ['шапк', 'шляп', 'шапочк'],
      'apparel.jaket' => ['пиджак'],
      'apparel.costume' => ['костюм'],
      'apparel.shirt' => ['рубашк', 'пуловер', 'толстовк'],
      'apparel.sock' => ['носки'],
      'apparel.tshirt' => ['футболк'],
      'apparel.underwear' => ['трусы', 'бюстгал', 'нижнее белье'],

      'appliances.kitchen.refrigerators' => ['холодильник'],
      'appliances.kitchen.washer' => ['стиральн'],
      'appliances.kitchen.dishwasher' => ['посудомоечн'],
      'appliances.kitchen.blender' => ['блендер'],
      'appliances.kitchen.coffee_machine' => ['кофевар'],
      'appliances.kitchen.coffee_grinder' => ['кофемолк'],
      'appliances.kitchen.microwave' => ['микроволн'],
      'appliances.kitchen.mixer' => ['миксер'],
      'appliances.kitchen.toster' => ['тостер'],
      'appliances.kitchen.kettle' => ['чайник', 'термопот'],
      'appliances.environment.vacuum' => ['пылесос'],
      'appliances.environment.air_conditioner' => ['кондиционер', 'сплит-систем'],
      'appliances.environment.climate' => ['климатическ'],
      'appliances.environment.air_heater' => ['конвектор', 'тепловентилят', 'обогревател'],
      'appliances.environment.water_heater' => ['водонагревател', ''],
      'appliances.environment.fan' => ['вентилятор'],
      'appliances.iron' => ['утюг'],
      'appliances.personal.epilator' => ['эпиллятор'],

      'electronics.camera.photo' => ['canon', 'nikon', 'pentax', 'объектив', 'бленда'],
      'electronics.camera.video' => ['видеокамер'],
      'electronics.video.projector' => ['проектор'],
      'electronics.video.tv' => ['телевизор'],
      'electronics.audio.acoustic' => ['акустик', 'акустичес'],
      'electronics.audio.dictaphone' => ['диктофон'],
      'electronics.audio.music_tools.piano' => ['синтезатор', 'midi'],
      'electronics.audio.headphone' => ['наушник'],
      'electronics.clocks' => ['часы'],
      'electronics.smartphone' => ['смартфон'],
      'electronics.telephone' => ['телефон'],
      'electronics.tablet' => ['планшет'],

      'computers.desktop' => ['компьютер', 'моноблок'],
      'computers.notebook' => ['ноутбук', 'ультрабук'],
      'computers.gaming' => ['игровая консоль', 'игровые консоли', 'playstation', 'x-box', 'psp'],
      'computers.peripherals.mouse' => ['мыши'],
      'computers.peripherals.monitor' => ['монитор'],
      'computers.peripherals.keyboard' => ['клавиатур'],
      'computers.peripherals.printer' => ['принтер'],
      'computers.peripherals.camera' => ['веб-камер'],
      'computers.network.router' => ['маршрутизатор', 'роутер'],
      'computers.software.operating_system' => ['операционные системы'],
      'computers.software.office' => ['офисные приложения'],
      'computers.software.accounting' => ['бухгалтерские приложения'],

      'cosmetic' => [],

      'construction.tools.drill' => ['дрель', 'дрели', 'сверл', 'перфоратор'],
      'construction.tools.saw' => ['пила', 'пилы'],
      'construction.tools.lawn_mower' => ['газонокосил'],
      'construction.tools.pump' => ['насос'],
      'construction.tools.welding' => ['сварочн', 'сварк'],
      'construction.tools.generator' => ['генератор'],

      'furniture.living_room.sofa' => ['диван', 'тахта'],
      'furniture.living_room.cabinet' => ['шкаф'],
      'furniture.bedroom.bed' => ['кроват'],
      'furniture.kitchen.table' => ['столы'],
      'furniture.kitchen.chair' => ['стул'],
      'furniture.bathroom.bath' => ['ванны', 'ванна'],
      'furniture.bathroom.mirror' => ['зеркало', 'зеркала'],

      'auto.accessories.videoregister' => ['видеорегистратор', 'видео-регистратор', 'видео регистратор'],
      'auto.accessories.immobilizer' => ['иммобилайзер'],
      'auto.accessories.acoustic' => ['автоакустика'],

      'banking.equipment' => ['банковское оборудование', 'счетчики банкнот'],

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
        return k if name.mb_chars.downcase.scan(word).any?
      end
    end

    nil

  end




end
