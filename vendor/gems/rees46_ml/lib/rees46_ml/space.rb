module Rees46ML
  class Space < Rees46ML::Element

    attribute :min, String, lazy: true
    attribute :max, String, lazy: true
    attribute :final, String, lazy: true

  end
end
