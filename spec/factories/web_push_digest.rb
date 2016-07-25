FactoryGirl.define do
  factory :web_push_digest do
    shop_id { SecureRandom.random_number(100) }
  end
end
