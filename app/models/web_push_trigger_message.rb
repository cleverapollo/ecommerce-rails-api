class WebPushTriggerMessage < ActiveRecord::Base

  belongs_to :shop
  belongs_to :client
  belongs_to :web_push_trigger

  validates :shop_id, presence: true
  validates :client_id, presence: true
  validates :web_push_trigger_id, presence: true
  validates :trigger_data, presence: true

  before_create :set_date

  scope :clicked, -> { where(clicked: true) }
  scope :showed, -> { where(showed: true) }
  scope :unsubscribed, -> { where(unsubscribed: true) }
  scope :previous_month, -> { where(date: 1.month.ago.beginning_of_month.to_date..1.month.ago.end_of_month.to_date) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current) }

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
      self.date = Date.current if self.date.blank?
    end
  end

end
