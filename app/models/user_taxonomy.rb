class UserTaxonomy < MasterTable
  belongs_to :user

  class << self

    def track(user, items, shop)
      category_ids = items.map { |x| x.category_ids }.flatten.uniq
      if category_ids.any?
        taxonomies = ItemCategory.where(shop: items.first.shop_id).where('taxonomy is not null').where(external_id: category_ids).pluck(:taxonomy).uniq
        taxonomies.each do |taxonomy|
          begin
            UserTaxonomy.find_or_create_by date: Date.current, taxonomy: taxonomy, user_id: user.id
          rescue ActiveRecord::RecordNotUnique
          end
        end
      end

      if shop.category.present? && shop.category.taxonomy.present?
        begin
          UserTaxonomy.find_or_create_by date: Date.current, taxonomy: shop.category.taxonomy, user_id: user.id
        rescue ActiveRecord::RecordNotUnique
        end
      end

    end

  end

end
