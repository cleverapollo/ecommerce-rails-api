##
# Клиент (тот, кто регается на rees46.com)
#
class Customer < MasterTable

  has_many :shops

  scope :admins, -> { where(role: 0) }

  class << self
    def default_manager
      Customer.new(first_name: 'Дмитрий', last_name: 'Зубенко', email: 'dz@rees46.com')
    end
  end

  def name
    [first_name, last_name].compact.join(' ')
  end

  def change_balance(amount)
    update! balance: (balance + amount.to_i)
  end

end
