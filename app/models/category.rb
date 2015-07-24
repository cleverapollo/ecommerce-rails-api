##
# Категория магазина
#
class Category < ActiveRecord::Base

  establish_connection MASTER_DB


  has_many :shops

  def wear?
    code == 'wear'
  end
end
