module Rees46ML
  class ShopLocation < Rees46ML::Element
    attribute :id, Rees46ML::SafeString
    attribute :type, Rees46ML::SafeString
    attribute :name, Rees46ML::SafeString
    attribute :parentId, Rees46ML::SafeString

    alias_method :parent_id, :parentId
    alias_method :parent_id=, :parentId=
  end
end