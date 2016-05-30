FactoryGirl.define do
  factory :subscribe_for_product_price do
    shop
    user
    item
    price { SecureRandom.random_number(100) }
  end
end
