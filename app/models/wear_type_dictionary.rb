class WearTypeDictionary < ActiveRecord::Base
  establish_connection MASTER_DB

  scope :by_type, ->(type_name) { where(type_name:type_name)}
end
