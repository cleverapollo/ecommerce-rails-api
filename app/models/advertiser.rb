class Advertiser < MasterTable

  validates :email, :first_name, :last_name, :company, :website, :mobile_phone, :work_phone, :country, :city, presence: true, length: { maximum: 255 }
  validates :cpm, numericality: {only_integer: true, greater_than: 0}, presence: true
  validates :priority, numericality: {only_integer: true, greater_than: 0}, presence: true

  has_many :advertiser_statistics, dependent: :nullify
  has_many :advertiser_shops
  has_many :shops, through: :advertiser_shops
  has_many :advertiser_item_categories
  has_many :item_categories, through: :advertiser_item_categories
  has_many :advertiser_purchases

  scope :active, -> { where(campaign_launched: true).where('balance > 0') }
  scope :prioritized, -> { order(priority: :desc) }

  # Изменяет баланс рекламодателя
  def change_balance(amount)
    update balance: (balance + amount)
  end



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

  # Активна ли рекламная кампания?
  def active?
    campaign_launched? && balance > 0
  end

end
