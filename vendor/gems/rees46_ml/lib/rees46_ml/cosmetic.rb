module Rees46ML
  class Cosmetic < Rees46ML::Element
    PART_TYPES = %w[hair face body intim hand leg]
    SKIN_TYPE = %w[dry normal oily comby]
    CONDITIONS = %w[colored damaged waved seborea akne loss grow dehydrated sensitive problem fading]

    attribute :gender, Rees46ML::Gender, lazy: true
    attribute :brand, String, default: "", lazy: true
    attribute :hypoallergenic, Rees46ML::Boolean, lazy: true
    attribute :periodic, Rees46ML::Boolean, lazy: true
    attribute :part_types, Set[Rees46ML::PartType], lazy: true
    attribute :skin_types, Set[Rees46ML::SkinType], lazy: true
    attribute :conditions, Set[String], lazy: true
    attribute :volumes, Set[Rees46ML::CosmeticVolume], lazy: true

    validates :hypoallergenic, inclusion: { in: (Rees46ML::Boolean::TRUE + Rees46ML::Boolean::FALSE) }
  end
end
