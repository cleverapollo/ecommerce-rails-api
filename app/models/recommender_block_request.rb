class RecommenderBlockRequest < ActiveRecord::Base
  establish_connection "#{Rails.env}_clickhouse".to_sym

  belongs_to :shop
  belongs_to :recommender_block
  belongs_to :session
end
