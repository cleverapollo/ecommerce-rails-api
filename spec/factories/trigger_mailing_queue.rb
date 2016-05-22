FactoryGirl.define do
  factory :trigger_mailing_queue do
    user_id { SecureRandom.random_number(100) }
    shop_id { SecureRandom.random_number(100) }
    recommended_items []
    source_items []
    email { Faker::Internet.email }
    trigger_type { TriggerMailings::Triggers::NAMES.sample.underscore }
    triggered_at { Time.current }
  end
end
