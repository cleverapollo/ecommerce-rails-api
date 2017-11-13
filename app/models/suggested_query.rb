class SuggestedQuery < ActiveRecord::Base
  belongs_to :shop
 
  validates :shop_id, :keyword, presence: true
  validates :keyword, uniqueness: { scope: :shop }

  scope :search_by_keywords, ->(words) { where('keyword iLIKE ANY (array[?])', words.map{ |i| "%#{i}%" }) }
  scope :order_by_score, -> { order("score desc") }
end
