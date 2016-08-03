FactoryGirl.define do
  factory :web_push_digest_message do
    shop_id { SecureRandom.random_number(100) }
    client_id { SecureRandom.random_number(100) }
    web_push_digest_id { SecureRandom.random_number(100) }
    web_push_digest_batch_id { SecureRandom.random_number(100) }
  end
end
