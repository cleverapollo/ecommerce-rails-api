module Rees46ML
  class Jewelry < Rees46ML::Element
    attribute :gender, Rees46ML::Gender, lazy: true
    attribute :ring_sizes, Set[Rees46ML::RingSize], lazy: true
    attribute :bracelet_sizes, Set[Rees46ML::BraceletSize], lazy: true
    attribute :chain_sizes, Set[Rees46ML::ChainSize], lazy: true
    attribute :jewelry_metal, String, lazy: true
    attribute :jewelry_color, String, lazy: true
    attribute :jewelry_gem, String, lazy: true
  end
end
