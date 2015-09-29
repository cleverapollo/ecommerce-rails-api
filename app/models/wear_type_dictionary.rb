class WearTypeDictionary < MasterTable
  scope :by_type, ->(type_name) { where(type_name:type_name)}
end
