##
# Связка пользователя (User) с магазином (Shop).
# В некоторых случаях объект User может отсутствовать.
#
class Client < ActiveRecord::Base

  belongs_to :shop
  belongs_to :user
  has_many :trigger_mails
  has_many :digest_mails

  before_create :assign_ab_testing_group

  validates :shop, presence: true

  scope :who_saw_subscription_popup, -> { where(subscription_popup_showed: true) }
  scope :with_email, -> { where('email IS NOT NULL') }
  scope :suitable_for_digest_mailings, -> { with_email.where(digests_enabled: true) }
  scope :ready_for_trigger_mailings, -> { with_email.where("triggers_enabled = 't' AND ((last_trigger_mail_sent_at is null) OR  last_trigger_mail_sent_at < NOW() - INTERVAL '14 days')") }

  class << self
    def relink_user(options = {})
      master = options.fetch(:to)
      slave = options.fetch(:from)

      where(user_id: slave.id).find_each do |slave_client|
        if master_client = find_by(shop_id: slave_client.shop_id, user_id: master.id)
          master_client.email = master_client.email || slave_client.email
          master_client.save if master_client.email_changed?

          slave_client.digest_mails.update_all(client_id: master_client.id)
          slave_client.trigger_mails.update_all(client_id: master_client.id)

          slave_client.delete
        else
          slave_client.update_columns(user_id: master.id)
        end
      end
    end
  end

  def user
    if super.present?
      super
    else
      new_user = create_user
      update_columns(user_id: new_user.id)
      new_user
    end
  end

  def digest_unsubscribe_url
    Routes.unsubscribe_subscriptions_url(type: 'digest', code: self.code || 'test', host: Rees46::HOST, shop_id: self.shop.uniqid)
  end

  def trigger_unsubscribe_url
    Routes.unsubscribe_subscriptions_url(type: 'trigger', code: self.code || 'test', host: Rees46::HOST, shop_id: self.shop.uniqid)
  end

  def unsubscribe_from(mailings_type)
    case mailings_type.to_sym
    when :digest
      update_columns(digests_enabled: false)
    when :trigger
      update_columns(triggers_enabled: false)
    end
  end

  def purge_email!
    if self.email.present?
      Client.where(email: self.email).update_all(email: nil)
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
