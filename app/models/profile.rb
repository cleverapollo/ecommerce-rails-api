class Profile
  include Mongoid::Document
  field :user_id, type: Integer
  field :gender, default: { :f => 50, :m => 50 }, type: Hash
  field :size, default: {}, type: Hash
  field :children, default: [], type: Array
  field :physiology, default: {}, type: Hash
  field :periodicly, default: {}, type: Hash
  field :profile_type, default: :main, type: Symbol

  index({ user_id: 1 }, { unique: true, background: true,  name: "user_id_index" })

  recursively_embeds_many

  def create_linked_profile(type, attributes)
    linked_profile = self.child_profiles
  end



end