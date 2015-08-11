##
# Клиент (тот, кто регается на rees46.com)
#
class Customer < ActiveRecord::Base

  establish_connection MASTER_DB

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

end
