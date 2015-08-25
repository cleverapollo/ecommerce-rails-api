class Medium < ActiveRecord::Base

  establish_connection MASTER_DB

  has_many :medium_actions
  has_many :articles

  validates :uniqid, presence: true, uniqueness: true
end
