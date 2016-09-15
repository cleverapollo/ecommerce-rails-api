class Visit < ActiveRecord::Base

  validates :shop_id, :user_id, :date, presence: true
  validates :shop_id, uniqueness: { scope: [:user_id, :date] }

  belongs_to :shop
  belongs_to :user

end
