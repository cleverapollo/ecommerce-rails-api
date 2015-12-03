module Rees46ML
  class Fashion < Rees46ML::Element
    TYPES = %w(shoe shirt tshirt underwear trouser jacket blazer sock belt hat glove).freeze
    FEATURES = %w(child pregnant adult).freeze

    attribute :brand,   Rees46ML::SafeString
    attribute :type,    Rees46ML::SafeString, default: 'tshirt'.freeze
    attribute :feature, Rees46ML::SafeString, default: 'adult'.freeze
    attribute :sizes,   Set[Rees46ML::Size]
    attribute :gender,  Rees46ML::Gender
  end
end
