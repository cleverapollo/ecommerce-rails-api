class Subscription < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user

  validates :shop, presence: true
  validates :user, presence: true

  scope :active, -> { where(active: true) }

  def to_json
    super(only: [:email, :name, :active, :declined])
  end

  def declined=value
    super(value)
    self.active = false if declined == true
  end

  def set_aside!
  end
end
