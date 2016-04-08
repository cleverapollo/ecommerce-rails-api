module Rees46ML
  class Fmcg < Rees46ML::Element

    attribute :hypoallergenic, Rees46ML::Boolean, lazy: true
    attribute :periodic, Rees46ML::Boolean, lazy: true
    attribute :volumes, Set[Rees46ML::FmcgVolume], lazy: true

    validates :hypoallergenic, inclusion: { in: (Rees46ML::Boolean::TRUE + Rees46ML::Boolean::FALSE) }
  end
end
