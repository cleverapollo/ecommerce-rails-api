##
# Связка пользователя (User) с магазином (Shop).
# В некоторых случаях объект User может отсутствовать.
#
class Client < ActiveRecord::Base
  include RequestLogger

  belongs_to :shop
  belongs_to :user
  has_many :trigger_mails
  has_many :digest_mails
  has_many :web_push_trigger_messages
  has_many :web_push_digest_messages
  has_many :web_push_tokens

  before_create :assign_ab_testing_group

  validates :shop, presence: true

  scope :who_saw_subscription_popup, -> { where('subscription_popup_showed IS TRUE') }
  scope :with_email, -> { where('email IS NOT NULL') }
  scope :suitable_for_digest_mailings, -> { with_email.where(digests_enabled: true) }
  scope :ready_for_trigger_mailings, -> (shop) { with_email.where("triggers_enabled IS TRUE AND ((last_trigger_mail_sent_at is null) OR last_trigger_mail_sent_at < ? )", shop.trigger_pause.days.ago).where('last_activity_at is not null and last_activity_at >= ?', 5.weeks.ago.to_date) }
  scope :ready_for_second_abandoned_cart, -> (shop) do
    trigger_mailing = TriggerMailing.where(shop: shop).where(trigger_type: 'abandoned_cart').select(:id)
    clients_ids = TriggerMail.where(shop: shop).where(created_at: 28.hours.ago..24.hours.ago).where(opened: false).where(trigger_mailing_id: trigger_mailing).select(:id)
    where(id: clients_ids).where(last_trigger_mail_sent_at: 28.hours.ago..24.hours.ago)
  end

  scope :ready_for_second_abandoned_cart_web_push, -> (shop) do
    web_push_trigger_id = WebPushTrigger.where(shop: shop).where(trigger_type: 'abandoned_cart').limit(1).pluck(:id).first
    clients_ids = WebPushTriggerMessage.where(shop: shop).where(created_at: 28.hours.ago..24.hours.ago).where(clicked: false).where(web_push_trigger_id: web_push_trigger_id).select(:id)
    where(id: clients_ids).where(last_web_push_sent_at: 28.hours.ago..24.hours.ago)
  end
  scope :ready_for_web_push_trigger, -> (shop) { where("web_push_enabled IS TRUE AND ((last_web_push_sent_at is null) OR last_web_push_sent_at < ? )", shop.trigger_pause.days.ago) }
  scope :ready_for_web_push_digest, -> { where("web_push_enabled IS TRUE") }





  class << self
    def relink_user(options = {})
      master_user = options.fetch(:to)
      slave_user = options.fetch(:from)

      where(user_id: slave_user.id).order(id: :desc).each do
        # @type slave_client [Client]
        |slave_client|

        # @type master_client [Client]
        master_client = where(shop_id: slave_client.shop_id, user_id: master_user.id).where.not(id: slave_client.id).order(:id).limit(1)[0]
        if master_client

          # Может возникнуть ситуация, что два client принадлежат одному user, поэтому master_user == slave_user
          # В связи с этим master_client может быть равен slave_client. В этой ситуации просто пропускаем обработку такого client
          next if master_client.id == slave_client.id

          master_client.email = master_client.email || slave_client.email
          master_client.save if master_client.email_changed?

          # Если оба client лежат в одном shop, то нужно объединить настройки рассылок и всего такого
          if master_client.shop_id == slave_client.shop_id
            master_client.bought_something = true if slave_client.bought_something?
            master_client.digests_enabled = false if !slave_client.digests_enabled? || !master_client.digests_enabled?
            master_client.subscription_popup_showed = true if slave_client.subscription_popup_showed?
            master_client.triggers_enabled = false if !slave_client.triggers_enabled? || !master_client.triggers_enabled?
            master_client.accepted_subscription = true if slave_client.accepted_subscription?
            master_client.ab_testing_group = slave_client.ab_testing_group if master_client.ab_testing_group != slave_client.ab_testing_group && !slave_client.ab_testing_group.nil?
            master_client.external_id = slave_client.external_id if !slave_client.external_id.blank? && master_client.external_id.blank?
            master_client.last_trigger_mail_sent_at = slave_client.last_trigger_mail_sent_at if !slave_client.last_trigger_mail_sent_at.nil?
            master_client.location = slave_client.location if !slave_client.location.nil?
            master_client.last_activity_at = slave_client.last_activity_at if master_client.last_activity_at.nil? || (!slave_client.last_activity_at.nil? && master_client.last_activity_at < slave_client.last_activity_at)
            master_client.supply_trigger_sent = slave_client.supply_trigger_sent if slave_client.supply_trigger_sent
            master_client.web_push_subscription_popup_showed = true if slave_client.web_push_subscription_popup_showed?
            master_client.accepted_web_push_subscription = true if slave_client.accepted_web_push_subscription?


            if slave_client.web_push_enabled?
              master_client.last_web_push_sent_at = slave_client.last_web_push_sent_at unless slave_client.last_web_push_sent_at.nil?
              master_client.web_push_enabled = true
            end

            master_client.save if master_client.changed?
          end

          # Перебрасываем токены веб пушей
          slave_client.web_push_tokens.each do
            # @type web_push_token [WebPushToken]
            |web_push_token|

            token = master_client.append_web_push_token(web_push_token.token.to_json)
            if token.client_id != master_client.id
              token.update(client_id: master_client.id)
            end
          end

          slave_client.digest_mails.update_all(client_id: master_client.id)
          slave_client.trigger_mails.update_all(client_id: master_client.id)
          slave_client.web_push_trigger_messages.update_all(client_id: master_client.id)
          slave_client.web_push_digest_messages.update_all(client_id: master_client.id)

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
      InvalidEmail.create(email: self.email, reason: 'mark_as_bounced')
      update email: nil
      # Client.where(email: self.email).update_all(email: nil)
    end
  end

  # Отмечает, что пользователь недавно что-то делал. Используется затем для выборки получателей триггеров
  def track_last_activity
    update last_activity_at: Date.current if last_activity_at != Date.current
  end

  # Подписывает клиента на триггерные рассылки
  # @return nil
  def subscribe_for_triggers!
    unless triggers_enabled?
      update triggers_enabled: true
    end
    nil
  end

  # Сбрасывает историю подписок на веб пуши, чтобы пользователь мог опять получить окно подписки.
  def clear_web_push_subscription!
    update web_push_enabled: false, web_push_subscription_popup_showed: nil, accepted_web_push_subscription: nil
  end

  # Append a new token
  # @param token [String]
  # @return [WebPushToken]
  # @raise
  def append_web_push_token(token)
    begin
      token = JSON.parse(token).deep_symbolize_keys
    rescue
      raise 'Invalid JSON data'
    end

    if token.present?

      # token already exist -> skip
      web_push_token = self.web_push_tokens.where(web_push_tokens: {shop_id: self.shop_id, token: token})
      return web_push_token if web_push_token.present?

      # detect browser
      browser = nil
      if token[:endpoint].present? && token[:keys].present?
        if token[:endpoint] =~ /google/
          browser = 'chrome'
        end
        if token[:endpoint] =~ /mozilla.com/
          browser = 'firefox'
        end
      elsif token[:browser] == 'safari'
        browser = token[:browser]
      else
        raise 'Token does not have right format'
      end

      # create a new token
      web_push_token = self.web_push_tokens.create!(shop_id: self.shop_id, token: token, browser: browser)
      self.update(web_push_enabled: true)

      return web_push_token
    end

    raise 'Token is not valid'
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
