class Article < ActiveRecord::Base
  belongs_to  :medium
  has_many    :medium_action

  validates :medium, presence: true
  validates :external_id, presence: true
end
