FactoryGirl.define do
  factory :item do
    uniqid
    price 100
    categories '{5}'
    url ''# 'http://example.com/item/123'
    image_url 'http://example.com/item/123.jpg'
    name 'test'
    description ''

    trait :widgetable do
      widgetable true
    end

    trait :available do
      is_available true
    end

    trait :recommendable do
      available
      ignored false
    end
  end
end
