class Profile
  include Mongoid::Document
  field :user_id, type: Integer
  field :gender, default: { :f => 50, :m => 50 }, type: Hash
  field :size, default: {}, type: Hash
  field :children, default: [], type: Hash
  field :physiology, default: {}, type: Hash
  field :periodicly, default: {}, type: Hash

  index({ user_id: 1 }, { unique: true, background: true,  name: "user_id_index" })
end