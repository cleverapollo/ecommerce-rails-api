FactoryGirl.define do
  factory :web_push_trigger do
    shop_id { SecureRandom.random_number(100) }
    trigger_type { WebPush::Triggers::NAMES.sample.underscore }
  end
end
