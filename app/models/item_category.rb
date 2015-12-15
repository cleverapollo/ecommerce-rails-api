##
# Категория товара.
#
class ItemCategory < ActiveRecord::Base

  belongs_to :shop

  validates :shop_id, presence: true
  validates :external_id, presence: true

  has_many :brand_campaign_item_categories
  has_many :item_categories, through: :brand_campaign_item_categories

  def self.bulk_update(shop_id, categories_tree)
    transaction do
      categories_tree.each do |yml_category|
        category = where(shop_id: shop_id, external_id: yml_category.id).first_or_create

        if yml_category.parent_id.present?
          yml_parent_category = categories_tree[yml_category.parent_id]

          parent_category = where(shop_id: shop_id, external_id: yml_parent_category.id).first_or_create

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
end
