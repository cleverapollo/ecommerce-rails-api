module Rees46ML
  class UnsupportedElement
    include Virtus.model

    attribute :name, Rees46ML::SafeString
    attribute :text, Rees46ML::SafeString
    attribute :attrs, Hash
    attribute :children, Array[Rees46ML::UnsupportedElement]

    alias_method :usupported_elements, :children

    def with_usupported_elements?
      usupported_elements.any?
    end
  end
end
