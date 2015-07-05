##
# Категория магазина
#
class Category < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  has_many :shops

  def wear?
    code == 'wear'
  end
end
