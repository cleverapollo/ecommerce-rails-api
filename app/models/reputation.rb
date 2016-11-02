class Reputation < ActiveRecord::Base

  belongs_to :shop
  belongs_to :entity, polymorphic: true
  belongs_to :parent, :class_name => "Reputation", :foreign_key => "parent_id"
  has_many :reputations, :class_name => "Reputation", :foreign_key => "parent_id"

  accepts_nested_attributes_for :reputations

  validates :shop, :entity, :rating, presence: true
end
