module Rees46ML
  class Perfume < Rees46ML::Element

    NAIL_TYPE = %w[floral citrus woody oriental fruity green oceanic spicy]

    attribute :aroma, Set[String], lazy: true

  end
end
