class WearTypeDictionary < MasterTable
  scope :by_type, ->(type_name) { where(type_name:type_name)}

  def self.index
    Rees46ML::Fashion::TYPES.map{ |size_type| [size_type, Regexp.union(WearTypeDictionary.by_type(size_type).pluck(:word).map{|word| Regexp.new(word, Regexp::IGNORECASE)})] }.to_h
  end
end
