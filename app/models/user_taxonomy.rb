class UserTaxonomy < MasterTable
  belongs_to :user

  # Порядок имеет значение по важности
  TYPES = %w(view remove_from_cart cart purchase rate)

  class << self

    def track(user, items, shop, event)

      event = nil if TYPES.index(event).nil?

      items.each do |item|
        if item.category_ids.is_a?(Array) && item.category_ids.any?
          category_ids = item.category_ids.flatten.uniq
          taxonomies = ItemCategory.where(shop: items.first.shop_id).where('taxonomy is not null').where(external_id: category_ids).pluck(:taxonomy).uniq
          taxonomies.each do |taxonomy|
            begin
              taxonomy = UserTaxonomy.find_by date: Date.current, taxonomy: taxonomy, user_id: user.id, brand: item.brand
              if taxonomy
                # Если в таксономии нет события или оно менее важное, чем нам передали, то обновляем его
                if taxonomy.event.nil? || TYPES.index(taxonomy.event).nil? || TYPES.index(taxonomy.event) < TYPES.index(event)
                  taxonomy.update event: event
                end
              else
                UserTaxonomy.create date: Date.current, taxonomy: taxonomy, user_id: user.id, brand: item.brand, event: event
              end
            rescue ActiveRecord::RecordNotUnique
            end
          end
        end
      end

      if shop.category.present? && shop.category.taxonomy.present?
        begin
          taxonomy = UserTaxonomy.find_by date: Date.current, taxonomy: shop.category.taxonomy, user_id: user.id
          if taxonomy
            # Если в таксономии нет события или оно менее важное, чем нам передали, то обновляем его
            if taxonomy.event.nil? || TYPES.index(taxonomy.event).nil? || TYPES.index(taxonomy.event) < TYPES.index(event)
              taxonomy.update event: event
            end
          else
            UserTaxonomy.create date: Date.current, taxonomy: taxonomy, user_id: user.id, event: event
          end
        rescue ActiveRecord::RecordNotUnique
        end
      end

    end

  end

end
