##
# Категория магазина
#
class Category < ActiveRecord::Base

  has_many :shops

  def wear?
    code == 'wear'
  end
end
