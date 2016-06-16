class SubscriptionPlan < MasterTable

  AVAILABLE_PRODUCTS = %w(rees46_recommendations rees46_remarketing rees46_triggers rees46_digests)

  validates :paid_till, :product, :shop_id, :price, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :product, inclusion: { in: AVAILABLE_PRODUCTS }

  belongs_to :shop

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :overdue, -> { where(active: true).where('paid_till < ?', Time.current) }

  AVAILABLE_PRODUCTS.each do |product|
    scope product.to_sym, -> { where(product: product) }
  end

  def overdue?
    active? && paid_till >= 1.month.ago && paid_till < Time.current
  end

  def paid?
    active? && paid_till >= Time.current
  end

end