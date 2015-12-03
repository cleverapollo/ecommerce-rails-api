module Rees46ML
  class Category < Rees46ML::Element
    attribute :id, Rees46ML::SafeString
    attribute :parentId, Rees46ML::SafeString
    attribute :name, Rees46ML::SafeString

    validates :id, :name, presence: true

    alias_method :category, :name
    alias_method :category=, :name=

    alias_method :parent_id, :parentId
    alias_method :parent_id=, :parentId=
  end
end