##
# Клиент (тот, кто регается на rees46.com)
#
class Customer < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  has_many :shops
end
