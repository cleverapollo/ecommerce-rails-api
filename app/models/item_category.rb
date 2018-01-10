##
# Категория товара.
#
class ItemCategory < ActiveRecord::Base

  belongs_to :shop

  validates :shop_id, presence: true
  validates :external_id, presence: true

  # has_many :brand_campaign_item_categories
  # has_many :item_categories, through: :brand_campaign_item_categories

  scope :widgetable,     -> { where('url is not null and name is not null') }

  class << self

    def bulk_update(shop_id, categories_tree)
      raise I18n.t('rees46_ml.error.invalid_categories') if categories_tree.nil?

      transaction do
        categories_tree.each do |yml_category|

          # Создаем категорию
          category_id = yml_insert(shop_id, yml_category)

          # Если указан родитель
          if yml_category.parent_id.present?

            # Создаем родителя
            yml_parent_category = categories_tree[yml_category.parent_id]
            if yml_parent_category.present?
              parent_category_id = yml_insert(shop_id, yml_parent_category)

              # Обновляем
              where(shop_id: shop_id, external_id: category_id).update_all(parent_id: parent_category_id)
            end
          end
        end
      end
    end

    # @param [Integer] shop_id
    # @param [Rees46ML::Category] yml_category
    # @return [Integer]
    def yml_insert(shop_id, yml_category)
      insert_or_update(
          shop_id: shop_id,
          external_id: yml_category.id,
          name: yml_category.name,
          parent_external_id: yml_category.parent_id.present? ? yml_category.parent_id : nil,
          url: yml_category.url.present? ? yml_category.url : nil,
      )
    end

    # Вставка строки или обновление при уникальности
    # @param [Hash] params
    # @return [Integer]
    def insert_or_update(params)

      record = new(params)
      unless record.valid?
        raise record.errors.full_messages.join(', ')
      end

      connection.insert(ActiveRecord::Base.send(:sanitize_sql_array, [
          "INSERT INTO item_categories (#{params.keys.join(', ')}, created_at, updated_at)
            VALUES(:#{params.keys.join(', :')}, now(), now())
            ON CONFLICT (shop_id, external_id)
            DO UPDATE SET #{params.keys.map {|k| "#{k} = excluded.#{k}"}.join(', ') }, updated_at = now()",
              params
      ])).to_i
    end
  end

end
