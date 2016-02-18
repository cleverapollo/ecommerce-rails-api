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
              txn = UserTaxonomy.find_by date: Date.current, taxonomy: taxonomy, user_id: user.id, brand: item.brand
              if txn
                # Если в таксономии нет события или оно менее важное, чем нам передали, то обновляем его
                if txn.event.nil? || TYPES.index(txn.event).nil? || TYPES.index(txn.event) < TYPES.index(event)
                  txn.update event: event
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
          txn = UserTaxonomy.find_by date: Date.current, taxonomy: shop.category.taxonomy, user_id: user.id
          if txn
            # Если в таксономии нет события или оно менее важное, чем нам передали, то обновляем его
            if txn.event.nil? || TYPES.index(txn.event).nil? || TYPES.index(txn.event) < TYPES.index(event)
              txn.update event: event
            end
          else
            UserTaxonomy.create date: Date.current, taxonomy: shop.category.taxonomy, user_id: user.id, event: event
          end
        rescue ActiveRecord::RecordNotUnique
        end
      end

    end

  end

end
