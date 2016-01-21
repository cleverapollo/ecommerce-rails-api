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

    return 'appliances.refrigerators' if name.mb_chars.downcase.scan('холодильник').any?
    return 'appliances.vacuum' if name.mb_chars.downcase.scan('пылесос').any?
    return 'appliances.blender' if name.mb_chars.downcase.scan('брендер').any?
    return 'appliances.air_conditioner' if name.mb_chars.downcase.scan('кондиционер').any?
    return 'appliances.coffee_machine' if name.mb_chars.downcase.scan('кофевар').any?
    return 'appliances.coffee_grinder' if name.mb_chars.downcase.scan('кофемолк').any?
    return 'appliances.microwave' if name.mb_chars.downcase.scan('микроволн').any?
    return 'appliances.mixer' if name.mb_chars.downcase.scan('миксер').any?
    return 'appliances.toster' if name.mb_chars.downcase.scan('тостер').any?
    return 'appliances.iron' if name.mb_chars.downcase.scan('утюг').any?
    return 'appliances.kettle' if name.mb_chars.downcase.scan('чайник').any?
    return 'appliances.epilator' if name.mb_chars.downcase.scan('эпиллятор').any?

    nil

  end




end
