FactoryGirl.define do
  factory :web_push_trigger_message do
    shop_id { SecureRandom.random_number(100) }
    client_id { SecureRandom.random_number(100) }
    web_push_trigger_id { SecureRandom.random_number(100) }
    code { SecureRandom.uuid }
    trigger_data { {a: 1} }
  end
end
