FactoryGirl.define do
  factory :item do
    uniqid
    price 100
    categories '{5}'
    is_available true
    ignored false
    url 'http://example.com/item/123'
    image_url 'http://example.com/item/123.jpg'
    name 'test'
    widgetable true
    description ''
  end
end
