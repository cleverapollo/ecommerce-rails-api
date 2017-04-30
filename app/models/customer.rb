##
# Клиент (тот, кто регается на rees46.com)
#
class Customer < MasterTable

  has_many :shops
  belongs_to :currency

  scope :admins, -> { where(role: 0) }

  class << self
    def default_manager(language = 'ru')
      name = (language.to_s == 'ru' ? { first: 'Поддержка', last: 'REES46'} : { first: 'REES46', last: 'Support'})
      Customer.new(first_name: name[:first], last_name: name[:last], email: Rails.configuration.support_email)
    end
  end

  def name
    [first_name, last_name].compact.join(' ')
  end

  def change_balance(amount)
    update! balance: (balance + amount.to_i)
  end

end
