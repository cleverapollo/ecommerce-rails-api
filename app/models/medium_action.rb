class MediumAction < ActiveRecord::Base
  belongs_to :medium
  belongs_to :user
  belongs_to :article

  validates :medium, presence: true
  validates :user, presence: true
  validates :article, presence: true
  validates :medium_action_type, presence: true
end
