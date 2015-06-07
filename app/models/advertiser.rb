class Advertiser < ActiveRecord::Base

  validates :email, :first_name, :last_name, :company, :website, :mobile_phone, :work_phone, :country, :city, :cpm, presence: true, length: { maximum: 255 }
  validates :cpm, numericality: {only_integer: true, greater_than: 0}

  has_many :advertiser_statistics, dependent: :nullify


  # Изменяет баланс рекламодателя
  def change_balance(amount)
    update balance: (balance + amount)
  end

end
