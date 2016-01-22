class UserTaxonomy < MasterTable
  belongs_to :user

  class << self

    def track(user, items)
      category_ids = items.map { |x| x.category_ids }.flatten.uniq
      if category_ids.any?
        taxonomies = ItemCategory.where(shop: items.first.shop_id).where('taxonomy is not null').where(external_id: category_ids)
        taxonomies.each do |taxonomy|
          UserTaxonomy.find_or_create_by date: Date.current, taxonomy: taxonomy, user_id: user.id
        end
      end
    end

  end

end
