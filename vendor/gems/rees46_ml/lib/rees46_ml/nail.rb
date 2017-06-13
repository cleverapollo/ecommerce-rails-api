module Rees46ML
  class Nail < Rees46ML::Element

    NAIL_TYPE = %w[tool polish gel oil cleaner]

    attribute :type, String, lazy: true
    attribute :polish_color, String, lazy: true

  end
end
