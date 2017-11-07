
class SearchQuery < ActiveRecord::Base

  belongs_to :shop
  belongs_to :user

  validates :shop_id, :user_id, :query, :date, presence: true

  include UserLinkable

  scope :created_within_days, ->(duration) { where('date >= ?', duration.days.ago.to_date) }
  scope :search_by_query, -> (query) { where('query LIKE ?', "%#{query.downcase}%") }

end
