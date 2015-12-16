module Rees46ML
  class UnsupportedElement
    include Virtus.model

    attribute :name, String, default: ""
    attribute :text, String, default: ""
    attribute :attrs, Hash
    attribute :children, Array[Rees46ML::UnsupportedElement]

    alias_method :usupported_elements, :children
  end
end
