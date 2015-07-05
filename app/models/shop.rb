##
# Магазин
#
class Shop < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  include Redis::Objects

  # Кол-во пользователей в тестовых группах
  counter :group_1_count
  counter :group_2_count

  # Состояние подключения
  store :connection_status_last_track, accessors: [:connected_events_last_track, :connected_recommenders_last_track], coder: JSON

  has_and_belongs_to_many :users
  belongs_to :plan
  belongs_to :customer
  belongs_to :category
  has_many :clients
  has_many :actions
  has_many :mahout_actions
  has_many :items
  has_many :orders
  has_many :subscriptions
  has_many :digest_mailings
  has_many :beacon_messages
  has_many :trigger_mailings
  has_many :item_categories
  has_many :events
  has_one :insales_shop
  has_one :digest_mailing_setting
  has_one :subscriptions_settings
  has_one :mailings_settings

  scope :with_yml, -> { where('yml_file_url is not null').where("yml_file_url != ''") }
  scope :with_enabled_triggers, -> { joins(:trigger_mailings).where('trigger_mailings.enabled = true').uniq }
  scope :active, -> { where(active: true) }
  scope :connected, -> { where(connected: true) }
  scope :unrestricted, -> { active.where(restricted: false) }
  scope :newbies, -> { unrestricted.where('connected_at >= ? OR created_at >= ?', 3.days.ago, 3.days.ago ) }

  # ID товаров, купленных или добавленных в корзину пользователем
  def item_ids_bought_or_carted_by(user)
    return [] if user.nil?
    actions.where('rating::numeric >= ?', Actions::Cart::RATING).where(user: user).where(repeatable: false).pluck(:item_id)
  end

  # Отследить отправленное событие
  def report_event(event)
    if connected_events_last_track[event].blank?
      Event.event_tracked(self) if first_event?
    end
      connected_events_last_track[event] = Date.current.to_time.to_i if !connected_events_last_track[event] || (connected_events_last_track[event] < Date.current.to_time.to_i)
      check_connection!
      save
  end

  # Отследить запрошенную рекомендацию
  def report_recommender(recommender)
    if connected_recommenders_last_track[recommender].blank?
      Event.recommendation_given(self) if first_recommender?
    end
    connected_recommenders_last_track[recommender] = Date.current.to_time.to_i if !connected_recommenders_last_track[recommender] || (connected_recommenders_last_track[recommender] < Date.current.to_time.to_i)
    check_connection!
    save
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

  def connected_now?
    (connected_events_last_track[:view].present? && connected_events_last_track[:purchase].present?) &&
    connected_events_last_track[:view] > (Date.current - 7).to_time.to_i && connected_events_last_track[:purchase] > (Date.current - 14).to_time.to_i &&
    (connected_recommenders_last_track.values.select{|v| v != nil }.count >= 3)
  end

  def show_promotion?
    self.manual == false && self.plan_id.present? && (self.paid == false || self.plan.try(:free?))
  end

  def subscriptions_enabled?
    subscriptions_settings.present? && subscriptions_settings.enabled?
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

  def payment_ended?
    connected && active && !manual && !plan_id.nil? && !paid_till.nil? && paid_till <= DateTime.current
  end

  def allow_industrial?
    !payment_ended? && plan.plan_type == 'custom'
  end

  def has_imported_yml?
    self.yml_loaded && self.last_valid_yml_file_loaded_at.present? && self.last_valid_yml_file_loaded_at >= 48.hours.ago
  end
end
