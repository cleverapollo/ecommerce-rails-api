##
# Связка пользователя (User) с магазином (Shop).
# В некоторых случаях объект User может отсутствовать.
#
class Client < ActiveRecord::Base
  include RequestLogger

  belongs_to :shop
  belongs_to :user
  belongs_to :session
  has_many :trigger_mails, dependent: :destroy
  has_many :digest_mails, dependent: :destroy
  has_many :web_push_trigger_messages, dependent: :destroy
  has_many :web_push_digest_messages, dependent: :destroy
  has_many :web_push_tokens, dependent: :destroy
  has_many :reputations
  has_many :orders, foreign_key: :user_id, primary_key: :user_id

  # Для партицируемых таблиц необходимо сначала получить ID, а потом создавать запись
  before_create :fetch_nextval

  before_create :assign_ab_testing_group
  before_save :fix_empty_segment

  validates :shop, presence: true

  serialize :audience_sources, Array
  serialize :external_audience_sources, Hash

  scope :who_saw_subscription_popup, -> { where(subscription_popup_showed: true) }
  scope :with_email, -> { joins('JOIN shop_emails ON shop_emails.email = clients.email AND shop_emails.shop_id = clients.shop_id') }
  scope :email_confirmed, -> { with_email.where(shop_emails: { email_confirmed: true }) }
  scope :ready_for_trigger_mailings, -> (shop, last_activity = 5.weeks.ago.to_date) do
    if shop.double_opt_in_by_law?
      email_confirmed.where('triggers_enabled = true AND last_activity_at IS NOT NULL AND last_activity_at >= ?', last_activity).where('((last_trigger_mail_sent_at is null) OR last_trigger_mail_sent_at < ? )', shop.trigger_pause.days.ago)
    else
      with_email.where('triggers_enabled = true AND last_activity_at IS NOT NULL AND last_activity_at >= ?', last_activity).where('((last_trigger_mail_sent_at is null) OR last_trigger_mail_sent_at < ? )', shop.trigger_pause.days.ago)
    end
  end
  # Пока у клиентов не может быть сегментов, т.к. перенесено в ShopEmail
  # В будущем будут сегменты для вебпушей
  scope :with_segment, -> (segment_id) { where('clients.segment_ids @> ARRAY[?]', segment_id) }
  scope :with_segments, -> (segment_ids) { where('clients.segment_ids && ARRAY[?]::int[]', segment_ids) }


  scope :ready_for_second_abandoned_cart, -> (shop) do
    clients_ids = TriggerMail.where(shop: shop, created_at: 28.hours.ago..24.hours.ago, opened: false, trigger_mailing_id: shop.trigger_abandoned_cart_id).where('"date" >= ?', 28.hours.ago.to_date).select(:client_id)
    with_email.where(id: clients_ids).where(shop_emails: { last_trigger_mail_sent_at: 28.hours.ago..24.hours.ago })
  end

  scope :ready_for_second_abandoned_cart_web_push, -> (shop) do
    clients_ids = WebPushTriggerMessage.where(shop: shop, created_at: 28.hours.ago..24.hours.ago, clicked: false, web_push_trigger_id: shop.web_push_trigger_abandoned_cart_id).where('"date" >= ?', 28.hours.ago.to_date).select(:client_id)
    where(id: clients_ids).where(last_web_push_sent_at: 28.hours.ago..24.hours.ago)
  end
  scope :ready_for_web_push_trigger, -> (shop) { where('web_push_enabled = true AND ((last_web_push_sent_at is null) OR last_web_push_sent_at < ? )', shop.trigger_pause.days.ago) }
  scope :ready_for_web_push_digest, -> { where(web_push_enabled: true) }


  class << self
    def relink_user(options = {})
      master_user = options.fetch(:to)
      slave_user = options.fetch(:from)

      where(user_id: slave_user.id).order(id: :desc).each do |slave_client|
        slave_client.merge_to(master_user)
      end
    end

    # @param [User] master
    # @param [Integer] slave_id
    def relink_user_remnants(master, slave_id)
      where(user_id: slave_id).each do |slave_client|
        slave_client.merge_to(master)
      end
    end
  end

  def user
    @user ||= super || create_user

    # Если создали нового юзера
    if self.user_id_changed?
      update_columns(user_id: @user.id)
    end
    @user
  end

  # @return [ClientCart]
  def cart
    @cart ||= ClientCart.find_by(shop: shop, user: user)
  end

  # @return [ShopEmail]
  def shop_email
    @shop_email ||= ShopEmail.find_by(shop_id: shop_id, email: email) if email.present?
  end

  # Обновляет email у клиента и запускает сбор профиля, если он изменился
  # @param [String] email
  def update_email(email)
    old_email = self.email
    self.email = email

    # Если запись запись была обновлена
    if self.email_changed?
      self.atomic_save!

      # Добавляем в список email магазина
      ShopEmail.fetch(shop, email) if email.present?

      # Запускаем сбор информации о профиле пользователя
      PropertyCalculatorWorker.perform_async(email) if email.present? || old_email.present?
    end
  end

  # Перенос объекта к указанному юзеру
  # @param [User] user
  def merge_to(user)
    relation = Client.where(shop_id: self.shop_id, user_id: user.id).where.not(id: self.id)

    # Если у текущего клиента есть fb_id, то мы не можем сливать с клиентами, у которых тоже указан fb_id
    if self.fb_id.present?
      relation = relation.where(fb_id: nil)
    end

    # Если у текущего клиента есть vk_id, то мы не можем сливать с клиентами, у которых тоже указан vk_id
    if self.vk_id.present?
      relation = relation.where(vk_id: nil)
    end

    # @type master_client [Client]
    master_client = relation.order(:id).limit(1)[0]
    if master_client.present?

      # Может возникнуть ситуация, что два client принадлежат одному user, поэтому master_client == self
      # В связи с этим master_client может быть равен self. В этой ситуации просто пропускаем обработку такого client
      return if master_client.id == self.id

      master_client.email = master_client.email || self.email
      master_client.fb_id = master_client.fb_id || self.fb_id
      master_client.vk_id = master_client.vk_id || self.vk_id
      master_client.atomic_save if master_client.changed?

      # Если оба client лежат в одном shop, то нужно объединить настройки рассылок и всего такого
      if master_client.shop_id == self.shop_id
        master_client.bought_something = true if self.bought_something?
        master_client.subscription_popup_showed = true if self.subscription_popup_showed?
        master_client.accepted_subscription = true if self.accepted_subscription?
        master_client.ab_testing_group = self.ab_testing_group if master_client.ab_testing_group != self.ab_testing_group && !self.ab_testing_group.nil?
        master_client.external_id = self.external_id if !self.external_id.blank? && master_client.external_id.blank?
        master_client.location = self.location if !self.location.nil?
        master_client.last_activity_at = self.last_activity_at if master_client.last_activity_at.nil? || (!self.last_activity_at.nil? && master_client.last_activity_at < self.last_activity_at)
        master_client.supply_trigger_sent = self.supply_trigger_sent if self.supply_trigger_sent
        master_client.web_push_subscription_popup_showed = true if self.web_push_subscription_popup_showed?
        master_client.web_push_subscription_permission_showed = true if self.web_push_subscription_permission_showed?
        master_client.accepted_web_push_subscription = true if self.accepted_web_push_subscription?


        if self.web_push_enabled?
          master_client.last_web_push_sent_at = self.last_web_push_sent_at unless self.last_web_push_sent_at.nil?
          master_client.web_push_enabled = true
        end

        master_client.atomic_save if master_client.changed?
      end

      # Перебрасываем токены веб пушей
      self.web_push_tokens.each do
        # @type web_push_token [WebPushToken]
        |web_push_token|

        token = master_client.append_web_push_token(web_push_token.token.to_json)
        if token.client_id != master_client.id
          token.update(client_id: master_client.id)
        end
      end

      self.digest_mails.update_all(client_id: master_client.id)
      self.trigger_mails.update_all(client_id: master_client.id)
      self.web_push_trigger_messages.update_all(client_id: master_client.id)
      self.web_push_digest_messages.update_all(client_id: master_client.id)

      Client.where(shop_id: self.shop_id, id: self.id).delete_all
    else
      self.update_columns(user_id: user.id)
    end
  end

  # @param [DigestMail] digest_mail
  # @deprecated
  def digest_unsubscribe_url(digest_mail)
    Routes.unsubscribe_subscriptions_url(type: 'digest', code: self.code || 'test', host: Rees46::HOST, shop_id: self.shop.uniqid, mail_code: digest_mail.try(:code))
  end

  # @param [TriggerMail] trigger_mail
  # @deprecated
  def trigger_unsubscribe_url(trigger_mail)
    Routes.unsubscribe_subscriptions_url(type: 'trigger', code: self.code || 'test', host: Rees46::HOST, shop_id: self.shop.uniqid, mail_code: trigger_mail.code)
  end

  def real_accepted_subscription?
    accepted_subscription && email.present?
  end

  # Отмечает, что пользователь недавно что-то делал. Используется затем для выборки получателей триггеров
  def track_last_activity
    if last_activity_at != Date.current
      Time.use_zone(shop.customer.time_zone) do
        assign_attributes last_activity_at: Date.current
        atomic_save! if changed?
      end
    end
  end

  # Подписывает клиента на триггерные рассылки
  # @return nil
  def subscribe_for_triggers!
    unless shop_email.triggers_enabled?
      shop_email.assign_attributes triggers_enabled: true
      shop_email.atomic_save! if shop_email.changed?
    end
    nil
  end

  # Сбрасывает историю подписок на веб пуши, чтобы пользователь мог опять получить окно подписки.
  def clear_web_push_subscription!
    assign_attributes web_push_enabled: false, web_push_subscription_popup_showed: nil, web_push_subscription_permission_showed: nil, accepted_web_push_subscription: nil
    atomic_save! if changed?
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
      web_push_token = self.web_push_tokens.find_by(web_push_tokens: {shop_id: self.shop_id, token: token})
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
      self.update(web_push_enabled: true, web_push_subscription_popup_showed: true, web_push_subscription_permission_showed: true, accepted_web_push_subscription: true)

      return web_push_token
    end

    raise 'Token is not valid'
  end

  # Добавляет сегмент к пользователю
  # @param [Integer] segment_id
  def add_segment(segment_id)
    self.segment_ids ||= []
    self.segment_ids << segment_id unless self.segment_ids.include? segment_id
    self
  end

  # Обновление текущего клиента с дополнительным фильтром для нужной партиции
  def atomic_save
    if new_record?
      super
    elsif changed?
      attrs = {}
      changed.each do |c|
        attrs[c] = self[c]
      end
      Client.where(shop_id: self.shop_id, id: self.id).update_all(attrs)
      changes_applied
      true
    else
      true
    end
  end
  def atomic_save!
    atomic_save or raise ActiveRecordError.new('Client save not updated')
  end

  # Обновление текущего клиента с дополнительным фильтром для нужной партиции
  def update_columns(attributes)
    Client.where(shop_id: self.shop_id, id: self.id).update_all(attributes)
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

  # Исправляет значение сегмента, если пустой массив
  def fix_empty_segment
    self.segment_ids = nil if !self.segment_ids.nil? && self.segment_ids.empty?
  end

  def fetch_nextval
    self.id = Client.connection.select_value("SELECT nextval('clients_id_seq')") unless self.id
  end

end
