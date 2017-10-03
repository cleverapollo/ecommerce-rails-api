class ThematicCollectionSection < ActiveRecord::Base
  belongs_to :thematic_collection
  belongs_to :shop
end
