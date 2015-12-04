module Rees46ML
  class Cosmetic < Rees46ML::Element
    PART_TYPES = %w[hair face body intim hand leg]
    SKIN_TYPE = %w[dry normal oily comby]
    CONDITIONS = %w[colored damaged waved seborea akne loss grow dehydrated sensitive problem fading]

    attribute :gender, Rees46ML::Gender
    attribute :brand, Rees46ML::SafeString
    attribute :hypoallergenic, Rees46ML::Boolean
    attribute :periodic, Rees46ML::Boolean
    attribute :part_types, Set[Rees46ML::PartType]
    attribute :skin_types, Set[Rees46ML::SkinType]
    attribute :conditions, Set[Rees46ML::SafeString]
    attribute :volumes,    Set[Rees46ML::CosmeticVolume]
  end
end
