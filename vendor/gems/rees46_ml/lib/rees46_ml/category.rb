module Rees46ML
  class Category < Rees46ML::Element
    attribute :id, String, default: "", lazy: true
    attribute :parentId, String, default: "", lazy: true
    attribute :name, String, default: "", lazy: true
    attribute :url, String, default: "", lazy: true

    validates :id, :name, presence: true

    alias_method :category, :name
    alias_method :category=, :name=

    alias_method :parent_id, :parentId
    alias_method :parent_id=, :parentId=
  end
end
