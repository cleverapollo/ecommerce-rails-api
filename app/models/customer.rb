##
# Клиент (тот, кто регается на rees46.com)
#
class Customer < ActiveRecord::Base

  establish_connection MASTER_DB


  has_many :shops
end
