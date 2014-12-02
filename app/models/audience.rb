class Audience < ActiveRecord::Base
  validates_presence_of :shop_id, :external_id, :email, :enabled
  serialize :custom_attributes, JSON

  belongs_to :shop
  belongs_to :user

  scope :enabled, -> { where(enabled: true) }

  def try_to_attach_to_user!
    if user_id.nil?
      if u_s_r = UserShopRelation.find_by(uniqid: external_id.to_s)
        update(user: u_s_r.user)
      end
    end
  end
end
