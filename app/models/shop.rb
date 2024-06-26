require 'addressable/uri'

##
# Магазин
#
class Shop < ActiveRecord::Base

  include Redis::Objects

  GEO_LAWS = {
    none: nil,
    eu: 1,
    canada: 2,
    usa: 3
  }

  # Кол-во пользователей в тестовых группах
  counter :group_1_count
  counter :group_2_count

  # Состояние подключения
  store :connection_status_last_track, accessors: [:connected_recommenders_last_track], coder: JSON

  has_many :thematic_collections
  has_many :vendor_campaigns
  has_and_belongs_to_many :users
  belongs_to :customer
  has_many :experiments
  has_many :catalog_import_logs
  has_many :web_push_triggers
  has_many :web_push_digests
  has_many :subscription_plans
  has_many :web_push_digest_messages
  has_many :web_push_trigger_messages
  has_many :profile_events
  belongs_to :category
  belongs_to :manager, -> { admins }, class_name: 'Customer'
  has_many :clients
  has_many :items
  has_many :orders
  has_many :order_items
  has_many :subscriptions
  has_many :digest_mailings
  has_many :trigger_mailings
  has_many :item_categories
  has_many :events
  has_one :insales_shop
  has_one :digest_mailing_setting
  has_one :subscriptions_settings
  has_one :web_push_subscriptions_settings
  has_one :search_setting
  has_one :mailings_settings
  has_many :shop_metrics
  has_many :search_queries
  has_many :subscribe_for_product_prices
  has_many :subscribe_for_product_availables
  has_many :reputations
  has_many :client_carts
  has_many :segments
  has_many :shop_locations
  has_many :recommender_blocks
  has_many :shop_inventories
  has_many :no_result_queries
  has_many :search_query_redirects
  has_many :suggested_queries
  has_many :shop_emails

  has_attached_file :logo, styles: { original: '500x500>', main: '170>x', medium: '130>x', small: '100>x' }
  validates_attachment_content_type :logo, content_type: /\Aimage/
  validates_attachment_file_name :logo, matches: [/png\Z/i, /jpe?g\Z/i]

  scope :with_valid_yml, -> { where('yml_file_url is not null').where("yml_file_url != ''").where("yml_errors < 5" ) }
  scope :with_yml_processed_recently, -> { where('last_valid_yml_file_loaded_at IS NOT NULL AND last_valid_yml_file_loaded_at > ?', 1.week.ago) }
  scope :with_enabled_triggers, -> { where(id: TriggerMailing.where(enabled: true).pluck(:shop_id).uniq ) }
  scope :with_enabled_web_push_triggers, -> { where(id: WebPushTrigger.where(enabled: true).pluck(:shop_id).uniq ) }
  scope :with_web_push_balance, -> { where('with_web_push_balance > 0') }
  scope :active, -> { where(active: true) }
  scope :connected, -> { where(connected: true) }
  scope :unrestricted, -> { active.where(restricted: false) }
  scope :mailings_unrestricted, -> { active.where(mailings_restricted: false) }
  scope :newbies, -> { unrestricted.where('connected_at >= ? OR created_at >= ?', 3.days.ago, 3.days.ago ) }
  scope :with_tracking_orders_status, -> { where(track_order_status: true) }

  # ID товаров, купленных или добавленных в корзину пользователем
  # Купленные исключаем только те товары, которые не периодические
  # Корзину ограничиваем неделей
  def item_ids_bought_or_carted_by(user)
    return [] if user.nil?
    carted_list = ClientCart.find_by(shop_id: id, user_id: user.id).try(:items) || []
    purchased_list = items.where(id: OrderItem.where(order_id: user.orders.where(shop_id: self.id)).select(:item_id)).not_periodic.pluck(:id)
    carted_list + purchased_list
  end

  # Отследить запрошенную рекомендацию
  def report_recommender(recommender)
    if connected_recommenders_last_track[recommender].blank?
      Event.recommendation_given(self) if first_recommender?
    end
    if connected_recommenders_last_track[recommender].nil? || connected_recommenders_last_track[recommender].to_i < Time.current.to_i
      connected_recommenders_last_track[recommender] = Time.current.to_i
    end
    atomic_save if changed?
  end

  def yml
    @yml ||= begin
      update_columns(last_try_to_load_yml_at: DateTime.current)
      normalized_uri = ::Addressable::URI.parse(yml_file_url.strip).normalize
      file = Rees46ML::File.new(Yml.new(normalized_uri, self.customer.language))
      update_columns(yml_loaded: true)
      file
    rescue NotRespondingError => ex
      ErrorsMailer.yml_url_not_respond.deliver_now
      Rollbar.error(ex, "Yml not respond", attributes.select{|k,_| k =~ /yml/}.merge(shop_id: self.id))
      update_columns(yml_loaded: false, yml_state: 'failed')
    rescue NoXMLFileInArchiveError => ex
      I18n.locale = customer.language
      ErrorsMailer.yml_import_error(self, I18n.t('yml_errors.no_files_in_archive')).deliver_now
      Rollbar.error(ex, "Не обнаружено XML-файлов в архиве.", attributes.select{|k,_| k =~ /yml/}.merge(shop_id: self.id))
      update_columns(yml_loaded: false, yml_state: 'failed')
    rescue => ex
      update_columns(yml_loaded: false, yml_state: 'failed')
      Rollbar.error(ex, "YML importing failed", attributes.select{|k,_| k =~ /yml/}.merge(shop_id: self.id))
      raise
    end
  end

  # Импорт YML файлов всех активных магазинов
  def self.import_yml_files
    active.connected.with_valid_yml.where('yml_load_start_at IS NULL or yml_load_start_at < now() - INTERVAL \'1 day\'').each do |shop|
      if shop.yml_allow_import?
        shop.async_yml_import
      elsif shop.yml_errors >= 5
        ErrorsMailer.yml_off(shop).deliver_now
      end
    end
  end

  def yml_expired?
    last_valid_yml_file_loaded_at.present? ? ((last_valid_yml_file_loaded_at.utc + yml_load_period.hours) < Time.now.utc) : true
  end

  def yml_allow_import?
    yml_expired? && ((yml_errors || 0) < 5) && (yml_state.nil? || yml_state == 'failed')
  end


  # Попытка загрузить YML позднее, чем последняя успешная обработка YML
  # При этом, во избежание ситуации "начали, но не удалось загрузить" ошибок обработки YML не было
  # # Если не было успешной обработки и не было ошибок
  # def yml_not_processing_now?
  #   # 1. Если не было попытки начать загрузку YML.
  #   return false if last_try_to_load_yml_at.nil?
  #   # Если загрузка была, а обработки не было. Значит сейчас обрабатыватся. Либо сломалось и тогда будет ошибка. Но ошибка уже могла быть и до этого.  успешной обработки не было, но загрузка файла была
  #   # 3. Если загрузка файла раньше, чем успешная обработка.
  #   return false if !last_valid_yml_file_loaded_at.nil? && last_try_to_load_yml_at <= last_valid_yml_file_loaded_at
  #   true
  # end

  def yml_allow_import!
    update(last_valid_yml_file_loaded_at: (Time.now.utc - yml_load_period.hours), yml_errors: 0)
  end

  # Создает очередь на обработку YML
  # @param [Boolean] force Флаг, что насильно переимпортировать файл, игнорируя if-modified-since
  def async_yml_import(force = false)

    # Добавляем статус
    self.update(yml_state: 'queue')

    # Добавляем задачу на обработку yml
    YmlImporter.perform_async(self.id, force)
  end

  # @return [Boolean]
  def import
    begin
      # Указываем время начала
      update_attribute(:yml_load_start_at, Time.now)
      yield yml if block_given?
      update(last_valid_yml_file_loaded_at: Time.now, yml_errors: 0, yml_state: nil)
      return true
    rescue PG::TRDeadlockDetected => e
      Rollbar.warning(e, 'Perhaps there was a backup', shop_id: id)
    rescue Yml::InvalidYMLSyntax => e
      ErrorsMailer.yml_syntax_error(self, e.message).deliver_now
      update_columns(yml_loaded: false, yml_state: 'failed')
      import_error(e, e.message)
    rescue Yml::NoXMLFileInArchiveError => e
      import_error(e, 'Incorrect YML archive')
    rescue Yml::NotXMLFile => e
      import_error(e, I18n.t('yml_errors.no_xml_file'))
    rescue ActiveRecord::RecordNotUnique => e
      import_error(e, I18n.t('yml_errors.no_uniq_ids'))
    rescue Errno::ECONNREFUSED => e
      import_error(e, e.message)
    rescue Interrupt => e
      Rollbar.info(e, 'Sidekiq shutdown, abort YML processing', shop_id: id)
    rescue Sidekiq::Shutdown => e
      Rollbar.info(e, 'Sidekiq shutdown, abort YML processing', shop_id: id)
    rescue ActiveRecord::StatementInvalid => e
      if e.message.match(/^PG::CardinalityViolation/).present?
        import_error(e, I18n.t('yml_errors.no_uniq_ids'))
      else
        import_error(e, 'YML process error')
      end
    rescue Exception => e
      import_error(e, 'YML process error')
    ensure
      update_attribute(:yml_load_start_at, nil)
    end

    false
  end

  # @param [Exception] e
  # @param [String] message
  def import_error(e, message)
    raise e unless Rails.env.production?
    I18n.locale = customer.language
    ErrorsMailer.yml_import_error(self, message).deliver_now
    Rollbar.warning(e, message, shop_id: id)
    update(yml_errors: self.yml_errors + 1, yml_state: 'failed')
    CatalogImportLog.create shop_id: id, success: false, message: message
  end

  def first_recommender?
    connected_recommenders_last_track.values.select{|v| v != true }.none?
  end

  def check_connection!
    if self.connected == false && connected_now?
      self.connected = true
      self.connected_at = Time.current
      atomic_save! if changed?
      Event.connected(self)
    end
  end

  # returns array of search keyword with synonyms
  def query_with_synonyms
    query_with_synonyms = self.no_result_queries.with_synonyms.map{ |no_result_query| "#{no_result_query.query}, #{no_result_query.synonym}" }
    query_with_synonyms.any? ? query_with_synonyms : [","]
  end

  # Проверяет подключен ли магазин
  # @return [Boolean]
  def events_connected?
    # Проверяем подключен ли магазин
    event_connected?('view') && event_connected?('purchase')
  end

  # Проверяет было ли событие
  # @param [String] event
  # @param [Hash]   options
  # @return [Boolean]
  def event_connected?(event, options = {})
    return false if events_connected[event].blank?

    light = options[:light] || false
    days = options[:days] || (event == 'view' || event == 'cart') ? 7 : 14
    return 'standby' if light && events_connected[event] <= (Date.current - days)
    events_connected[event] >= (Date.current - days)
  end

  # Получаем события магазина
  # @return [Hash] {"view" => Date, "cart" => Date, ... }
  def events_connected
    @events_connected ||= EventsConnected.for_shop(self.id)
  end

  # Проверяет, считается ли магазин подключенным.
  # Подключенным считаем магазины, у которых были события просмотра и покупки не позднее 7 и 14 дней соответственно.
  # Раньше считали еще 3 разных рекомендера, но сейчас это не требуется.
  # IDEA: возможно, стоит добавить проверку YML. Но это отрицательно скажется на иностранных клиентах.
  # @return Boolean
  def connected_now?
    event_connected?('view', days: 1) && event_connected?('cart', days: 1) && event_connected?('purchase', days: 2)
  end

  # Оформлена подписка и попап включен?
  def subscriptions_enabled?
    @subscriptions_plan ||= self.subscription_plans.subscriptions.first
    subscriptions_settings.present? && subscriptions_settings.enabled? && @subscriptions_plan.present? && @subscriptions_plan.paid?
  end

  # Включен ли поисковый движок?
  def search_enabled?
    subscription_plans.product_search.paid.exists?
  end

  # Check if shop has enabled web push subscriptions
  # @return Boolean
  def web_push_subscriptions_enabled?
    web_push_subscriptions_settings.present? && web_push_subscriptions_settings.enabled?
  end

  def domain
    url.split('://').last.split('www.').last.split('/').first
  end

  def deactivated?
    !active?
  end

  def restricted?
    super || deactivated?
  end

  def has_imported_yml?
    self.yml_file_url.present? && self.yml_loaded && self.yml_errors < 5
  end

  def double_opt_in_by_law?
    self.geo_law != GEO_LAWS[:none]
  end

  # @return [Boolean]
  def send_confirmation_email_trigger?
    @double_opt_in_enabled ||= self.trigger_mailings.find_by(trigger_type: 'double_opt_in').try(:enabled) && double_opt_in_by_law?
  end

  # Уменьшает количество веб пушей на балансе на 1 после отправки
  def reduce_web_push_balance!
    if web_push_balance > 0
      Shop.connection.update("UPDATE shops SET web_push_balance = web_push_balance - 1 WHERE #{ActiveRecord::Base.send(:sanitize_sql_array, ['id = ?', self.id])}")
      self.reload
    else
      Rollbar.warning(shop: id, message: 'reduce_web_push_balance when web_push_balance = 0')
    end
  end

  def fetch_logo_url
    self.logo.present? ? URI.join("#{Rees46.site_url}", self.logo.url).to_s : ''
  end

  # Проверяет наличие отраслевых товаров разных категорий и отмечает их флаги
  def check_industrial_products
    self.has_products_jewelry = items.recommendable.where('is_jewelry IS TRUE').exists?
    self.has_products_kids = items.recommendable.where('is_child IS TRUE').exists?
    self.has_products_fashion = items.recommendable.where('is_fashion IS TRUE').exists?
    self.has_products_pets = items.recommendable.where('is_pets IS TRUE').exists?
    self.has_products_cosmetic = items.recommendable.where('is_cosmetic IS TRUE').exists?
    self.has_products_fmcg = items.recommendable.where('is_fmcg IS TRUE').exists?
    self.has_products_auto = items.recommendable.where('is_auto IS TRUE').exists?
    self.has_products_realty = items.recommendable.where('is_realty IS TRUE').exists?
    atomic_save if changed?
  end

  # Все необходимые записи установлены в DNS домена?
  # @return [Boolean]
  def mailing_dig_verify?
    mailings_settings.mailing_service != MailingsSettings::MAILING_SERVICE_REES46 || verify_domain.try(:[], 'domain') && verify_domain.try(:[], 'spf') && verify_domain.try(:[], 'dkim') && verify_domain.try(:[], 'dmarc')
  end

  # Trigger mailing cache ids
  # @return [Integer]
  def trigger_abandoned_cart_id
    @trigger_abandoned_cart_id ||= TriggerMailing.where(shop_id: self.id).where(trigger_type: 'abandoned_cart').pluck(:id).first
  end

  # Trigger mailing cache ids
  # @return [Integer]
  def trigger_second_abandoned_cart_id
    @trigger_second_abandoned_cart_id ||= TriggerMailing.where(shop_id: self.id).where(trigger_type: 'second_abandoned_cart').pluck(:id).first
  end

  # Web push trigger cache ids
  # @return [Integer]
  def web_push_trigger_abandoned_cart_id
    @web_push_trigger_abandoned_cart_id ||= WebPushTrigger.where(shop_id: self.id).where(trigger_type: 'abandoned_cart').pluck(:id).first
  end
end
