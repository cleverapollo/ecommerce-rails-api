class Reputation < ActiveRecord::Base
  STATUSES = {
    moderation: 0,
    published: 1,
    banned: 2
  }

  belongs_to :shop
  belongs_to :entity, polymorphic: true
  belongs_to :parent, :class_name => "Reputation", :foreign_key => "parent_id"
  has_many :reputations, :class_name => "Reputation", :foreign_key => "parent_id"

  accepts_nested_attributes_for :reputations

  validates :shop, :entity, :rating, presence: true

  scope :for_shop, -> { where(entity_type: 'Order') }
  scope :for_items, -> { where(entity_type: 'Item') }
  scope :published, -> { where(status: STATUSES[:published])}
end
