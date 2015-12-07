module Rees46ML
  class Shop < Rees46ML::Element
    validates :name, :company, :url, presence: true

    attribute :name, Rees46ML::SafeString
    attribute :company, Rees46ML::SafeString
    attribute :url, Rees46ML::SafeString
    attribute :phone, Rees46ML::SafeString
    attribute :platform, Rees46ML::SafeString
    attribute :phone, Rees46ML::SafeString
    attribute :store, Rees46ML::Boolean
    attribute :version, Rees46ML::SafeString
    attribute :agency, Rees46ML::SafeString
    attribute :email, Set[Rees46ML::SafeString]
    attribute :currencies, Set[Rees46ML::Currency]
    attribute :delivery_options, Set[Rees46ML::DeliveryOption]
    attribute :store, Rees46ML::Boolean
    attribute :pickup, Rees46ML::Boolean
    attribute :delivery, Rees46ML::Boolean
    attribute :deliveryIncluded, Rees46ML::SafeString
    attribute :adult, Rees46ML::Boolean
    attribute :local_delivery_cost, Rees46ML::SafeString
    attribute :adult, Rees46ML::SafeString
    attribute :cpa, Rees46ML::SafeString
    attribute :fee, Rees46ML::SafeString

    attribute :categories, Rees46ML::Tree, default: ->(*){ Rees46ML::Tree.new }
    attribute :locations,  Rees46ML::Tree, default: ->(*){ Rees46ML::Tree.new }
  end
end