# https://yandex.ru/support/partnermarket/elements/delivery-options.xml

module Rees46ML
  class DeliveryOption < Rees46ML::Element
    attribute :cost, Integer, lazy: true
    attribute :days, String, default: "", lazy: true
    attribute :order_before, String, default: "", lazy: true
  end
end
