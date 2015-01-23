class ShopsUser < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user

  before_create :assign_ab_testing_group

  validates :shop, presence: true

  scope :who_saw_subscription_popup, -> { where(subscription_popup_showed: true) }
  scope :with_email, -> { where('email IS NOT NULL') }
  scope :suitable_for_digest_mailings, -> { with_email.where(digests_enabled: true) }

  def digest_unsubscribe_url
    Rails.application.routes.url_helpers.unsubscribe_subscriptions_url(type: 'digest', code: self.code || 'test', host: Rees46.host)
  end

  def trigger_unsubscribe_url
    Rails.application.routes.url_helpers.unsubscribe_subscriptions_url(type: 'trigger', code: self.code || 'test', host: Rees46.host)
  end

  def unsubscribe_from_triggers!
    update_columns(triggers_enabled: false)
  end

  def unsubscribe_from_digests!
    update_columns(digests_enabled: false)
  end

  def purge_email!
    if self.email.present?
      ShopsUser.where(email: self.email).update_all(email: nil)
    end
  end

  protected
    def assign_ab_testing_group
      return if self.ab_testing_group.present?

      if shop.group_1_count.to_i > shop.group_2_count.to_i
        self.ab_testing_group = 2
      else
        self.ab_testing_group = 1
      end

      shop.send("group_#{self.ab_testing_group}_count").incr
    end
end
