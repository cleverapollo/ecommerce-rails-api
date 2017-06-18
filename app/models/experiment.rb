class Experiment < ActiveRecord::Base
  validates :shop_id, :segments, :name, presence: true
  validates :segments, numericality: {greater_than: 1, only_integer: true, less_than: 10 }
end
