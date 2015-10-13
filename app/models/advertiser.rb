class Advertiser < MasterTable

  # Prevent from changes
  after_find :protect_it

  has_many :brand_campaigns

  def first_in_selection(item_ids)
    Item.where(id:item_ids, brand:downcase_brand).where.not(brand:nil).by_sales_rate.limit(1)[0].try(:id)
  end

  def first_in_categories(shop_id, categories, excluded_ids=[])
    Item.in_categories(categories, any:true).where(shop_id:shop_id, brand:downcase_brand).where.not(id: excluded_ids, brand:nil)
        .by_sales_rate.limit(1)[0].try(:id)
  end

  def get_from_categories(relation, shop_id, categories, excluded_ids=[], limit=8)
    relation.in_categories(categories, any:true).where(shop_id:shop_id, brand:downcase_brand).where.not(id: excluded_ids, brand:nil)
        .by_sales_rate.order(price: :desc).limit(limit).pluck(:id)
  end

  def first_in_shop(shop_id, excluded_ids=[])
    Item.where(shop_id:shop_id, brand:downcase_brand).where.not(id:excluded_ids, brand:nil)
        .by_sales_rate.limit(1)[0].try(:id)
    
  end

end
