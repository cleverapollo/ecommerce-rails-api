class ClientError < ActiveRecord::Base
  belongs_to :shop

  store :params, coder: JSON

  validates :exception_class, presence: true
  validates :exception_message, presence: true
  validates :params, presence: true

  default_scope -> { where(resolved: false) }

  def to_s
    "[#{shop.try(:uniqid)}] #{exception_class}: #{exception_message}, params: #{params}"
  end

  def resolve!
    update_attribute(:resolved, true)
  end
end
