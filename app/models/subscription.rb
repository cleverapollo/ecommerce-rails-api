class Subscription < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user

  validates :shop, presence: true
  validates :user, presence: true

  scope :active, -> { where(active: true) }

  DONT_DISTURB_DAYS_COUNT = 14

  def to_json
    super(only: [:email, :name, :active, :declined])
  end

  def declined=value
    super(value)
    self.active = false if declined == true
  end

  def deactivate!
    update(active: false)
  end

  # Отметить, что эту подписку не нужно беспокоить какое-то время
  def set_dont_disturb!
    update(dont_disturb_until: DONT_DISTURB_DAYS_COUNT.days.from_now)
  end
end
