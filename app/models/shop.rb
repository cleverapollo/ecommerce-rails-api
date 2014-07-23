class Shop < ActiveRecord::Base
  include Redis::Objects
  counter :group_1_count
  counter :group_2_count

  store :connection_status, accessors: [:connected_events, :connected_recommenders], coder: JSON

  belongs_to :customer
  has_and_belongs_to_many :users
  has_many :shops_users
  has_many :actions
  has_many :mahout_actions
  has_many :orders
  has_one :insales_shop
  has_many :user_shop_relations
  has_many :items

  def report_event(event)
    if connected_events[event] != true
      ShopEventsReporter.event_tracked(self) if first_event?
      connected_events[event] = true
      check_connection!
      save
    end
  end

  def report_recommender(recommender)
    if connected_recommenders[recommender] != true
      ShopEventsReporter.recommendation_given(self) if first_recommender?
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
      self.trial_ends_at = 1.month.from_now
      ShopEventsReporter.connected(self) 
    end
  end

  def connected_now?
    connected_events[:view] == true && connected_events[:purchase] == true && (connected_recommenders.values.select{|v| v == true }.count >= 3)
  end

  def available_item_ids
    items.available.pluck(:id)
  end

  def purge_all_related_data!
    users.delete_all
    ShopsUser.where(shop_id: self.id).delete_all
    actions.delete_all
    mahout_actions.delete_all
    orders.destroy_all
    items.destroy_all
  end
end
