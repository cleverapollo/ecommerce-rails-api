module Rees46ML
  class Fashion < Rees46ML::Element
    TYPES = %w(shoe shirt tshirt underwear trouser jacket blazer sock belt hat glove).freeze
    FEATURES = %w(child pregnant adult).freeze

    attribute :brand,   String, default: "", lazy: true
    attribute :type,    String, default: "", default: 'tshirt'.freeze, lazy: true
    attribute :feature, String, default: "", default: 'adult'.freeze, lazy: true
    attribute :sizes,   Set[Rees46ML::Size], lazy: true
    attribute :gender,  Rees46ML::Gender, lazy: true
  end
end
