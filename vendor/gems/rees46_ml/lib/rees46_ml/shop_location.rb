module Rees46ML
  class ShopLocation < Rees46ML::Element
    attribute :id, String, default: ""
    attribute :type, String, default: ""
    attribute :name, String, default: ""
    attribute :parentId, String, default: ""

    alias_method :parent_id, :parentId
    alias_method :parent_id=, :parentId=
  end
end