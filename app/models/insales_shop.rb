##
# Магазин на InSales.
#
class InsalesShop < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  belongs_to :shop
end
