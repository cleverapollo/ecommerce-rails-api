##
# Категория магазина
#
class Category < MasterTable

  has_many :shops

  def wear?
    code == 'wear'
  end
end
