module Rees46ML
  class Cosmetic < Rees46ML::Element

    attribute :gender, Rees46ML::Gender, lazy: true
    attribute :hypoallergenic, Rees46ML::Boolean, lazy: true
    attribute :periodic, Rees46ML::Boolean, lazy: true
    attribute :skin, Rees46ML::Skin, lazy: true
    attribute :hair, Rees46ML::Hair, lazy: true
    attribute :volumes, Set[Rees46ML::CosmeticVolume], lazy: true

    validates :hypoallergenic, inclusion: { in: (Rees46ML::Boolean::TRUE + Rees46ML::Boolean::FALSE) }
  end
end
