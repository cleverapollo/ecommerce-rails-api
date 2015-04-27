##
# Клиент (тот, кто регается на rees46.com)
#
class Customer < ActiveRecord::Base
  has_many :shops
end
