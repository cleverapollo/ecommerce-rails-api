module Rees46ML
  class Realty < Rees46ML::Element

    attribute :type, String, lazy: true
    attribute :space, Rees46ML::Space, lazy: true

  end
end
