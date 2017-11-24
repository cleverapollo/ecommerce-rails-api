##
# Клиент (тот, кто регается на rees46.com)
#
class Customer < ActiveRecord::Base

  has_many :shops
  belongs_to :currency
  has_many :customer_balance_histories, dependent: :delete_all

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

  def change_balance(amount, message)
    old_balance = self.balance
    if amount.to_i < 0
      Customer.connection.update(ActiveRecord::Base.send(:sanitize_sql_array, ['UPDATE customers SET balance = balance - ? WHERE id = ?', amount.to_i.abs, self.id]))
    else
      Customer.connection.update(ActiveRecord::Base.send(:sanitize_sql_array, ['UPDATE customers SET balance = balance + ? WHERE id = ?', amount.to_i, self.id]))
    end
    self.reload

    begin
      customer_balance_histories.create!(message: "#{message}: #{old_balance} => #{self.balance} (#{amount})")
    rescue Exception => e
      Rollbar.error e, customer: self.id, amount: amount
    end
  end

end
