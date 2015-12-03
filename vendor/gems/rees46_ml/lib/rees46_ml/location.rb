module Rees46ML
  class Location < Rees46ML::Element
    attribute :id, Rees46ML::SafeString
    attribute :type, Rees46ML::SafeString
    attribute :name, Rees46ML::SafeString
    attribute :prices, Set[Rees46ML::Price]
    attribute :path, Array
  end
end