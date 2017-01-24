FactoryGirl.define do
  factory :web_push_digest do
    subject { Faker::Lorem.word }
    message { Faker::Lorem.word }
    url { Faker::Lorem.word }
    shop_id { SecureRandom.random_number(100) }
  end
end
