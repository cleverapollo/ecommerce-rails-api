module Rees46ML
  class Skin < Rees46ML::Element

    SKIN_PARTS = %w[face body intim hand leg]
    SKIN_TYPE = %w[dry normal oily comby]
    SKIN_CONDITION = %w[dehydrated sensitive problem fading]

    attribute :part, Set[String], lazy: true
    attribute :type, Set[String], lazy: true
    attribute :condition, Set[String], lazy: true

  end
end