module Rees46ML
  class Auto < Rees46ML::Element
    attribute :periodic, Rees46ML::Boolean, lazy: true
    attribute :compatibility, Set[Rees46ML::Compatibility], lazy: true
    attribute :vds, Set[String], lazy: true
  end
end
