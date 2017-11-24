class CustomerBalanceHistory < ActiveRecord::Base
  belongs_to :customer

  validates :customer_id, :message, presence: true
end
