class Profile
  include Mongoid::Document
  field :user_id, type: Integer
  field :gender, default: { :f => 50, :m => 50 }, type: Hash
  field :size, default: {}, type: Hash
  field :children, default: [], type: Array
  field :physiology, default: {}, type: Hash
  field :periodicly, default: {}, type: Hash
  field :linked, default:{}, type: Hash

  index({ user_id: 1 }, { unique: true, background: true,  name: "user_id_index" })

  def create_linked_profile(type, attributes={})
    user = User.create
    attributes['user_id'] = user.id
    profile = Profile.create(attributes)
    linked_prof = self.linked
    linked_prof[type]||=[]
    linked_prof[type].push(profile['_id'])
    self.linked = linked_prof
  end

  def linked_profiles(type)
    self.linked[type]||=[]
    Profile.where(:_id.in=>self.linked[type])
  end

  def linked_gender_profile
    Profile.find(self.linked[:gender].first) if self.linked[:gender]
  end


end