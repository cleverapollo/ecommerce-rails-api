
class SearchQuery < ActiveRecord::Base

  belongs_to :shop
  belongs_to :user

  validates :shop_id, :user_id, :query, :date, presence: true

  include UserLinkable


end
