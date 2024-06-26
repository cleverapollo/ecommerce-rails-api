module Rees46ML
  class Fashion < Rees46ML::Element
    TYPES = %w(shoe shirt tshirt underwear trouser jacket blazer sock belt hat glove).freeze
    FEATURES = %w(child pregnant adult).freeze

    attribute :type,    String, lazy: true
    attribute :feature, String, default: 'adult'.freeze, lazy: true
    attribute :sizes,   Set[Rees46ML::Size], lazy: true
    attribute :gender,  Rees46ML::Gender, lazy: true
  end
end
