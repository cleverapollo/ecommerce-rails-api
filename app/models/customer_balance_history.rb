class CustomerBalanceHistory < MasterTable
  belongs_to :customer

  validates :customer_id, :message, presence: true
end
