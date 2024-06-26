class RtbImpression < ActiveRecord::Base
  validates :code, :bid_id, :ad_id, :price, :currency, :shop_id, :item_id, :user_id, presence: true

  belongs_to :shop
  belongs_to :item
  belongs_to :user
  belongs_to :rtb_job, foreign_key: :ad_id

  scope :clicks, -> { where(clicked: true) }

  def mark_as_purchased!
    update_columns(clicked: true, purchased: true) unless purchased?
  end

  def mark_as_clicked!
    update_columns(clicked: true) unless clicked?
  end

end
