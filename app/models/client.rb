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
  scope :ready_for_trigger_mailings, -> (shop) { with_email.where("triggers_enabled = 't' AND ((last_trigger_mail_sent_at is null) OR last_trigger_mail_sent_at < ? )", shop.trigger_pause.days.ago) }
  scope :ready_for_second_abandoned_cart, -> (shop) do
    trigger_mailing = TriggerMailing.where(shop: shop).find_by(trigger_type: 'abandoned_cart')
    clients_ids = TriggerMail.where(shop: shop).where(created_at: 28.hours.ago..24.hours.ago).where(opened: false).where(trigger_mailing_id: trigger_mailing.id).pluck(:client_id)
    where(id: clients_ids).where(last_trigger_mail_sent_at: 28.hours.ago..24.hours.ago)
  end

  class << self
    def relink_user(options = {})
      master_user = options.fetch(:to)
      slave_user = options.fetch(:from)

      where(user_id: slave_user.id).order(id: :desc).find_each do |slave_client|
        if master_client = where(shop_id: slave_client.shop_id, user_id: master_user.id).where.not(id: slave_client.id).order(:id).limit(1)[0]

          # Может возникнуть ситуация, что два client принадлежат одному user, поэтому master_user == slave_user
          # В связи с этим master_client может быть равен slave_client. В этой ситуации просто пропускаем обработку такого client
          next if master_client.id == slave_client.id

          master_client.email = master_client.email || slave_client.email
          master_client.save if master_client.email_changed?

          # Если оба client лежат в одном shop, то нужно объединить настройки рассылок и всего такого
          if master_client.shop_id == slave_client.shop_id
            master_client.bought_something = true if slave_client.bought_something?
            master_client.digests_enabled = true if slave_client.digests_enabled?
            master_client.subscription_popup_showed = true if slave_client.subscription_popup_showed?
            master_client.triggers_enabled = true if slave_client.triggers_enabled?
            master_client.accepted_subscription = true if slave_client.accepted_subscription?
            master_client.ab_testing_group = slave_client.ab_testing_group if master_client.ab_testing_group != slave_client.ab_testing_group && !slave_client.ab_testing_group.nil?
            master_client.external_id = slave_client.external_id if !slave_client.external_id.blank? && master_client.external_id.blank?
            master_client.last_trigger_mail_sent_at = slave_client.last_trigger_mail_sent_at if !slave_client.last_trigger_mail_sent_at.nil?
            master_client.location = slave_client.location if !slave_client.location.nil?
            master_client.last_supply_trigger_send_at = slave_client.last_supply_trigger_send_at if !slave_client.last_supply_trigger_send_at.nil?
            master_client.save if master_client.changed?
          end

          slave_client.digest_mails.update_all(client_id: master_client.id)
          slave_client.trigger_mails.update_all(client_id: master_client.id)

          slave_client.delete
        else
          slave_client.update_columns(user_id: master_user.id)
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
