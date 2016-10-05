class WebPushTriggerMessage < ActiveRecord::Base

  belongs_to :shop
  belongs_to :client
  belongs_to :web_push_trigger

  validates :shop_id, presence: true
  validates :client_id, presence: true
  validates :web_push_trigger_id, presence: true
  validates :trigger_data, presence: true

  before_create :set_date

  scope :clicked, -> { where('clicked IS TRUE') }

  store :trigger_data, coder: JSON


  # Отметить факт перехода
  def mark_as_clicked!
    update_columns(clicked: true) unless clicked?
  end


  # Отмечает отписавшихся
  def mark_as_unsubscribed!
    update_columns(unsubscribed: true) unless unsubscribed?
  end

  private

  def set_date
    Time.use_zone(shop.customer.time_zone) do
      self.date = Date.current
    end
  end

end
