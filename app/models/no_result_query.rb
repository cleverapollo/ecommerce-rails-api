class NoResultQuery < ActiveRecord::Base

  belongs_to :shop
  validates :shop_id, :query, presence: true
  scope :with_synonyms, -> { where("synonym is not null") }

end
