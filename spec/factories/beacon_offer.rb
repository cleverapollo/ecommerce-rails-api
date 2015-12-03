FactoryGirl.define do
  factory :beacon_offer do
    uuid { SecureRandom.uuid }
    major { SecureRandom.random_number(100).to_s }
    image_url { Faker::Lorem.phrase }
    title        { Faker::Lorem.phrase }
    notification { Faker::Lorem.phrase }
    description  { Faker::Lorem.phrase }
    enabled false
    shop_id { SecureRandom.random_number(100) }
  end
end
