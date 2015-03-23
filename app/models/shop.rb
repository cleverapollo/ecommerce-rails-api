class Shop < ActiveRecord::Base
  include Redis::Objects
  counter :group_1_count
  counter :group_2_count

  store :connection_status, accessors: [:connected_events, :connected_recommenders], coder: JSON

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
  scope :unrestricted, -> { active.where(restricted: false) }

  def item_ids_bought_or_carted_by(user)
    return [] if user.nil?
    actions.where('rating::numeric >= ?', Actions::Cart::RATING).where(user: user).where(repeatable: false).pluck(:item_id)
  end

  def report_event(event)
    if connected_events[event] != true
      Event.event_tracked(self) if first_event?
      connected_events[event] = true
      check_connection!
      save
    end
  end

  def report_recommender(recommender)
    if connected_recommenders[recommender] != true
      Event.recommendation_given(self) if first_recommender?
      connected_recommenders[recommender] = true
      check_connection!
      save
    end
  end

  def first_event?
    connected_events.values.select{|v| v == true }.none?
  end

  def first_recommender?
    connected_recommenders.values.select{|v| v == true }.none?
  end

  def check_connection!
    if self.connected == false && connected_now?
      self.connected = true
      self.connected_at = Time.current
      Event.connected(self)
    end
  end

  def connected_now?
    connected_events[:view] == true && connected_events[:purchase] == true && (connected_recommenders.values.select{|v| v == true }.count >= 3)
  end

  def purge_all_related_data!
    users.delete_all
    Client.where(shop_id: self.id).delete_all
    actions.delete_all
    mahout_actions.delete_all
    orders.destroy_all
    items.destroy_all
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

  def has_imported_yml?
    self.yml_loaded && self.last_valid_yml_file_loaded_at >= 48.hours.ago
  end
end
