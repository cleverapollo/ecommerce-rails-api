class Medium < MasterTable

  has_many :medium_actions
  has_many :articles

  validates :uniqid, presence: true, uniqueness: true
end
