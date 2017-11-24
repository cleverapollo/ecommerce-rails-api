class BrandCampaign < ActiveRecord::Base

  # Prevent from changes
  after_find :readonly!

  scope :active, -> { where(campaign_launched: true).where('balance > 0') }
  scope :prioritized, -> { order(priority: :desc) }
  scope :expansion, -> { where(is_expansion: true)}

  belongs_to :advertiser
  has_many :brand_campaign_item_categories
  has_many :brand_campaign_purchases
  has_many :brand_campaign_shops
  has_many :shops, through: :brand_campaign_shops
  has_many :brand_campaign_statistics, dependent: :nullify

  # Активна ли рекламная кампания?
  def active?
    campaign_launched? && balance > 0
  end




  # Ищет продвигаемый товар среди предоставленных и, если такой есть,
  # возвращает его идентификатор для последующей постановки на первое место.
  # @param item_ids [Array]
  # @param discount [Boolean] Искать только по скидочным товарам
  # @return Integer
  def first_in_selection(item_ids, discount = false)
    Slavery.on_slave do
      relation = Item.recommendable.widgetable.where(id:item_ids, brand:downcase_brand).where('brand IS NOT NULL').where('price >= ?', product_minimum_price).by_sales_rate
      relation = relation.discount if discount
      relation.limit(1)[0].try(:id)
    end
  end

  def first_in_categories(shop_id, categories, excluded_ids=[], discount = false, strict_categories = false)
    Slavery.on_slave do
      relation = Item.recommendable.widgetable.in_categories(categories, any: !strict_categories ).where(shop_id:shop_id, brand:downcase_brand).where('brand IS NOT NULL').where.not(id: excluded_ids).where('price >= ?', product_minimum_price).by_sales_rate
      relation = relation.discount if discount
      relation.limit(1)[0].try(:id)
    end
  end

  # @deprecated?
  # def get_from_categories(relation, shop_id, categories, excluded_ids=[], limit=8, discount = false)
  #   relation = relation.in_categories(categories, any:true).where(shop_id:shop_id, brand:downcase_brand).where.not(id: excluded_ids, brand:nil).where('price >= ?', product_minimum_price).by_sales_rate.order(price: :desc)
  #   relation.discount if discount
  #   relation.limit(limit).pluck(:id)
  # end

  def first_in_shop(shop_id, excluded_ids=[], discount = false)
    Slavery.on_slave do
      relation = Item.recommendable.widgetable.where(shop_id:shop_id, brand:downcase_brand).where('brand IS NOT NULL').where.not(id:excluded_ids).where('price >= ?', product_minimum_price).by_sales_rate
      relation = relation.discount if discount
      relation.limit(1)[0].try(:id)
    end
  end


end
