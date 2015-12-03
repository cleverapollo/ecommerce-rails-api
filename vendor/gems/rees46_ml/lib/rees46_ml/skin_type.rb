module Rees46ML
  class SkinType < Rees46ML::Element
    attribute :value, Rees46ML::SafeString

    alias_method :skin_type, :value
    alias_method :skin_type=, :value=
  end
end