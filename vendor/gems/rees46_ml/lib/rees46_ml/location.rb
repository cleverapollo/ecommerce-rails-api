module Rees46ML
  class Location < Rees46ML::Element
    attribute :id, String, default: "", lazy: true
    attribute :type, String, default: "", lazy: true
    attribute :name, String, default: "", lazy: true
    attribute :prices, Set[Rees46ML::Price], lazy: true
    attribute :path, Array, lazy: true
  end
end