##
# Аудитория дайджестных рассылок.
#
class Audience < ActiveRecord::Base
  validates_presence_of :shop_id, :external_id, :email
  serialize :custom_attributes, JSON

  belongs_to :shop
  belongs_to :user

  scope :active, -> { where(active: true) }

  # Попытка связать аудиторию с пользователем.
  def try_to_attach_to_user!
    if user_id.blank?
      if u_s_r = UserShopRelation.find_by(uniqid: external_id.to_s)
        update(user: u_s_r.user)
      end
    end
  end

  def deactivate!
    update(active: false)
  end

  def unsubscribe_url
    Rails.application.routes.url_helpers.unsubscribe_subscriptions_url(type: 'digest', code: self.code || 'test', host: Rees46.host)
  end
end
