module Rees46ML
  class Hair < Rees46ML::Element

    HAIR_TYPE = %w[dry normal oily comby]
    HAIR_CONDITION = %w[colored damaged waved seborea akne loss grow]

    attribute :type, Set[String], lazy: true
    attribute :condition, Set[String], lazy: true

  end
end