require 'addressable/uri'

##
# Магазин
#
class Shop < MasterTable

  include Redis::Objects

  # Кол-во пользователей в тестовых группах
  counter :group_1_count
  counter :group_2_count

  # Состояние подключения
  store :connection_status_last_track, accessors: [:connected_events_last_track, :connected_recommenders_last_track], coder: JSON

  has_and_belongs_to_many :users
  belongs_to :customer
  has_many :visits
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
  has_many :actions
  has_many :items
  has_many :orders
  has_many :order_items
  has_many :subscriptions
  has_many :digest_mailings
  has_many :beacon_messages
  has_many :trigger_mailings
  has_many :item_categories
  has_many :events
  has_one :insales_shop
  has_one :digest_mailing_setting
  has_one :subscriptions_settings
  has_one :web_push_subscriptions_settings
  has_one :mailings_settings
  has_many :beacon_offers
  has_many :shop_metrics
  has_many :search_queries
  has_many :subscribe_for_categories
  has_many :subscribe_for_product_prices
  has_many :subscribe_for_product_availables

  has_attached_file :logo, styles: { original: '500x500>', main: '170>x', medium: '130>x', small: '100>x' }
  validates_attachment_content_type :logo, content_type: /\Aimage/
  validates_attachment_file_name :logo, matches: [/png\Z/i, /jpe?g\Z/i]

  # Делаем так, чтобы в API были доступны только те магазины, которые принадлежат текущему шарду
  default_scope { where(shard: SHARD_ID) }

  scope :with_valid_yml, -> { where('yml_file_url is not null').where("yml_file_url != ''").where("yml_errors < 5" ) }
  scope :with_yml_processed_recently, -> { where('last_valid_yml_file_loaded_at IS NOT NULL') }
  scope :with_enabled_triggers, -> { where(id: TriggerMailing.where(enabled: true).pluck(:shop_id).uniq ) }
  scope :with_enabled_web_push_triggers, -> { where(id: WebPushTrigger.where(enabled: true).pluck(:shop_id).uniq ) }
  scope :with_web_push_balance, -> { where('with_web_push_balance > 0') }
  scope :active, -> { where(active: true) }
  scope :connected, -> { where(connected: true) }
  scope :unrestricted, -> { active.where(restricted: false) }
  scope :newbies, -> { unrestricted.where('connected_at >= ? OR created_at >= ?', 3.days.ago, 3.days.ago ) }
  scope :on_current_shard, -> { where(shard: SHARD_ID) }
  scope :with_tracking_orders_status, -> { where(track_order_status: true) }

  # ID товаров, купленных или добавленных в корзину пользователем
  def item_ids_bought_or_carted_by(user)
    return [] if user.nil?
    actions.where('rating::numeric >= ?', Actions::Cart::RATING).where(user: user).pluck(:item_id)
  end

  # Отследить отправленное событие
  def report_event(event)
    if connected_events_last_track[event].blank?
      Event.event_tracked(self) if first_event?
    end
    connected_events_last_track[event] = Time.current.to_i if !connected_events_last_track[event] || (connected_events_last_track[event] < Time.current.to_i)
    check_connection!
    save
  end

  # Отследить запрошенную рекомендацию
  def report_recommender(recommender)
    if connected_recommenders_last_track[recommender].blank?
      Event.recommendation_given(self) if first_recommender?
    end
    connected_recommenders_last_track[recommender] = Time.current.to_i if !connected_recommenders_last_track[recommender] || (connected_recommenders_last_track[recommender] < Time.current.to_i)
    check_connection!
    save
  end

  def yml
    @yml ||= begin
      update_columns(last_try_to_load_yml_at: DateTime.current)
      normalized_uri = ::Addressable::URI.parse(yml_file_url.strip).normalize
      file = Rees46ML::File.new(Yml.new(normalized_uri))
      update_columns(yml_loaded: true)
      file
    rescue NotRespondingError => ex
      ErrorsMailer.yml_url_not_respond.deliver_now
      Rollbar.error(ex, "Yml not respond", attributes.select{|k,_| k =~ /yml/}.merge(shop_id: self.id))
      update_columns(yml_loaded: false)
    rescue NoXMLFileInArchiveError => ex
      ErrorsMailer.yml_import_error(self, "Не обноружено XML-файлов в архиве.").deliver_now
      Rollbar.error(ex, "Не обнаружено XML-файлов в архиве.", attributes.select{|k,_| k =~ /yml/}.merge(shop_id: self.id))
      update_columns(yml_loaded: false)
    rescue => ex
      update_columns(yml_loaded: false)
      Rollbar.error(ex, "YML importing failed", attributes.select{|k,_| k =~ /yml/}.merge(shop_id: self.id))
      raise
    end
  end

  def self.import_yml_files
    active.connected.with_valid_yml.where(shard: SHARD_ID).each do |shop|
      if shop.yml_allow_import?
        YmlImporter.perform_async(shop.id)
      elsif shop.yml_errors >= 5
        ErrorsMailer.yml_off(shop).deliver_now
      end
    end
  end

  def yml_expired?
    last_valid_yml_file_loaded_at.present? ? ((last_valid_yml_file_loaded_at.utc + yml_load_period.hours) < Time.now.utc) : true
  end

  def yml_allow_import?
    yml_expired? && ((yml_errors || 0) < 5)
  end

  def yml_allow_import!
    update(last_valid_yml_file_loaded_at: (Time.now.utc - yml_load_period.hours), yml_errors: 0)
  end

  def import
    begin
      yield yml if block_given?
      update(last_valid_yml_file_loaded_at: Time.now, yml_errors: 0)
    rescue Yml::NoXMLFileInArchiveError => e
      Rollbar.warning(e, "Incorrect YML archive", shop_id: id)
      ErrorsMailer.yml_url_not_respond(self).deliver_now
      increment!(:yml_errors)
      CatalogImportLog.create shop_id: id, success: false, message: 'Incorrect YML archive'
    rescue ActiveRecord::RecordNotUnique => e
      Rollbar.warning(e, "Ошибка синтаксиса YML", shop_id: id)
      ErrorsMailer.yml_syntax_error(self, 'В YML-файле встречаются товары с одинаковыми идентификаторами. Каждое товарное предложение (оффер) должно содержать уникальный идентификатор товара, не повторяющийся в пределах одного YML-файла.').deliver_now
      increment!(:yml_errors)
      CatalogImportLog.create shop_id: id, success: false, message: 'Ошибка синтаксиса YML'
    rescue Interrupt => e
      Rollbar.info(e, "Sidekiq shutdown, abort YML processing", shop_id: id)
    rescue Exception => e
      ErrorsMailer.yml_import_error(self, e).deliver_now
      Rollbar.warning(e, "YML process error", shop_id: id)
      increment!(:yml_errors)
      CatalogImportLog.create shop_id: id, success: false, message: 'YML process error'
    end

  end

  def first_event?
    connected_events_last_track.values.select{|v| v != nil }.none?
  end

  def first_recommender?
    connected_recommenders_last_track.values.select{|v| v != true }.none?
  end

  def check_connection!
    if self.connected == false && connected_now?
      self.connected = true
      self.connected_at = Time.current
      Event.connected(self)
    end
  end

  # Проверяет, считается ли магазин подключенным.
  # Подключенным считаем магазины, у которых были события просмотра и покупки не позднее 7 и 14 дней соответственно.
  # Раньше считали еще 3 разных рекомендера, но сейчас это не требуется.
  # IDEA: возможно, стоит добавить проверку YML. Но это отрицательно скажется на иностранных клиентах.
  # @return Boolean
  def connected_now?
    (connected_events_last_track[:view].present? && connected_events_last_track[:purchase].present?) &&
    connected_events_last_track[:view] > (Date.current - 7).to_time.to_i && connected_events_last_track[:purchase] > (Date.current - 14).to_time.to_i # &&
    # (connected_recommenders_last_track.values.select{|v| v != nil }.count >= 3)
  end

  def ekomi?
    ekomi_enabled? && ekomi_id.present? && ekomi_key.present?
  end

  def subscriptions_enabled?
    subscriptions_settings.present? && subscriptions_settings.enabled?
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

  # Уменьшает количество веб пушей на балансе на 1 после отправки
  def reduce_web_push_balance!
    if web_push_balance > 0
      decrement! :web_push_balance, 1
    end
  end

  def fetch_logo_url
    self.logo.present? ? URI.join("#{Rees46.site_url}", self.logo.url).to_s : ''
  end

end
