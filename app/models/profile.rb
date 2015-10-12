class Profile
  include Mongoid::Document
  field :user_id, type: Integer
  field :gender, default: { :f => 50, :m => 50 }, type: Hash
  field :size, default: {}, type: Hash
  field :children, default: [], type: Array
  field :physiology, default: {}, type: Hash
  field :periodicly, default: {}, type: Hash

  index({ user_id: 1 }, { unique: true, background: true,  name: "user_id_index" })

  has_many :profiles, store_as: "linked_profiles"
  belongs_to :profile, store_as: "parent_profile"

end