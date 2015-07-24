##
# Магазин на InSales.
#
class InsalesShop < ActiveRecord::Base

  establish_connection MASTER_DB


  belongs_to :shop
end
