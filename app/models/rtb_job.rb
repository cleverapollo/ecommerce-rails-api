class RtbJob < ActiveRecord::Base
  validates :user_id, :shop_id, presence: true
  belongs_to :user
  belongs_to :shop
  has_many :rtb_impressions, foreign_key: :ad_id
  scope :active, -> { where('active IS TRUE') }

  scope :active_for_user, -> (user) { where(source_user_id: user.id).where('active IS TRUE').where('counter < 10').where('date >= ?', 2.days.ago.beginning_of_day).order(id: :desc) }


end
