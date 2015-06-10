class Advertiser < ActiveRecord::Base

  validates :email, :first_name, :last_name, :company, :website, :mobile_phone, :work_phone, :country, :city, :cpm, presence: true, length: { maximum: 255 }
  validates :cpm, numericality: {only_integer: true, greater_than: 0}

  has_many :advertiser_statistics, dependent: :nullify
  has_many :advertiser_shops
  has_many :shops, through: :advertiser_shops
  has_many :advertiser_item_categories
  has_many :item_categories, through: :advertiser_item_categories
  has_many :advertiser_purchases



  # Изменяет баланс рекламодателя
  def change_balance(amount)
    update balance: (balance + amount)
  end

  def in_name?(item_name)
    !item_name.match(/\b#{downcase_brand}\b/i).nil?
  end

  def first_in_selection(item_ids)
    Item.where(id:item_ids, brand:downcase_brand).where.not(brand:nil).first.try(:id)
  end

  def first_in_categories(shop_id, categories, excluded_ids=[])
    Item.in_categories(categories, any:true).where(shop_id:shop_id, brand:downcase_brand).where.not(id: excluded_ids, brand:nil).first.try(:id)
  end

  def first_in_shop(shop_id, excluded_ids=[])
    Item.where(shop_id:shop_id, brand:downcase_brand).where.not(id:excluded_ids, brand:nil).first.try(:id)
  end
end
