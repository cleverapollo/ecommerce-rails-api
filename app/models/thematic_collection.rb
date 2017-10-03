class ThematicCollection < ActiveRecord::Base
  validates :name, presence: true
  belongs_to :shop
  has_many :thematic_collection_sections
end
