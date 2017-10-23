class NoResultQuery < ActiveRecord::Base

  belongs_to :shop
  validates :shop_id, :query, presence: true
  validates :query, uniqueness: { scope: :shop }

  scope :with_synonyms, -> { where("synonym is not null") }

end
