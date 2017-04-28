class ShopLocation < ActiveRecord::Base

  belongs_to :shop

  validates :shop_id, presence: true
  validates :external_id, presence: { message: 'Location id can\'t be blank'}

  class << self

    # @param [Integer] shop_id
    # @param [Rees46ML::Tree] locations_tree
    def bulk_update(shop_id, locations_tree)
      transaction do
        locations_tree.each do |yml_location|

          # Создаем локацию
          location_id = ShopLocation.yml_insert(shop_id, yml_location)

          # Если указан родитель
          if yml_location.parent_id.present?

            # Создаем родителя
            yml_parent_location = locations_tree[yml_location.parent_id]
            parent_location_id = ShopLocation.yml_insert(shop_id, yml_parent_location)

            # Обновляем
            ShopLocation.where(shop_id: shop_id, external_id: location_id).update_all(parent_id: parent_location_id)
          end
        end
      end
    end

    # @param [Integer] shop_id
    # @param [Rees46ML::ShopLocation] yml_location
    # @return [Integer]
    def yml_insert(shop_id, yml_location)
      insert_or_update(shop_id: shop_id, external_id: yml_location.id, name: yml_location.name, external_type: yml_location.type, parent_external_id: yml_location.parent_id.present? ? yml_location.parent_id : nil)
    end

    # Вставка строки или обновление при уникальности
    # @param [Hash] params
    # @return [Integer]
    def insert_or_update(params)

      record = new(params)
      unless record.valid?
        raise record.errors.messages.values.join(', ')
      end

      connection.insert(ActiveRecord::Base.send(:sanitize_sql_array, [
          "INSERT INTO shop_locations (#{params.keys.join(', ')}, created_at, updated_at)
            VALUES(:#{params.keys.join(', :')}, now(), now())
            ON CONFLICT (shop_id, external_id)
            DO UPDATE SET #{params.keys.map {|k| "#{k} = excluded.#{k}"}.join(', ') }, updated_at = now()",
              params
      ])).to_i
    end
  end

end
