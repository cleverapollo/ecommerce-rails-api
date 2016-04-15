module Rees46ML
  class Child < Rees46ML::Element
    TYPES = %w[toy education nappy furniture school transport]

    attribute :age, Rees46ML::ChildAge, default: ->(*){ Rees46ML::ChildAge.new }, lazy: true
    attribute :type, String, lazy: true
    attribute :gender, Rees46ML::Gender, lazy: true

  end
end
