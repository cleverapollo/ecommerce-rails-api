module Rees46ML
  class Shop < Rees46ML::Element
    validates :name, :company, :url, presence: true

    attribute :name, String, default: ""#, lazy: true
    attribute :company, String, default: "", lazy: true
    attribute :url, String, default: "", lazy: true
    attribute :phone, String, default: "", lazy: true
    attribute :platform, String, default: "", lazy: true
    attribute :version, String, default: "", lazy: true
    attribute :agency, String, default: "", lazy: true
    attribute :email, String, default: "", lazy: true
    attribute :delivery_options, Set[Rees46ML::DeliveryOption], lazy: true
    attribute :store, Rees46ML::Boolean, lazy: true
    attribute :pickup, Rees46ML::Boolean, lazy: true
    attribute :delivery, Rees46ML::Boolean, lazy: true
    attribute :adult, Rees46ML::Boolean, lazy: true
    attribute :local_delivery_cost, String, default: "", lazy: true
    attribute :cpa, String, default: "", lazy: true

    attribute :currencies, Set[Rees46ML::Currency], lazy: true
    attribute :categories, Rees46ML::Tree, default: ->(*){ Rees46ML::Tree.new }, lazy: true
    attribute :locations,  Rees46ML::Tree, default: ->(*){ Rees46ML::Tree.new }, lazy: true
  end
end