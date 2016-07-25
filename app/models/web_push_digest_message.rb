class WebPushDigestMessage < ActiveRecord::Base


  belongs_to :shop
  belongs_to :client
  belongs_to :web_push_digest

  validates :shop_id, presence: true
  validates :client_id, presence: true
  validates :web_push_digest_id, presence: true

  before_create :set_date

  scope :clicked, -> { where('clicked IS TRUE') }


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
    self.date = Date.current
  end


end
