FactoryGirl.define do
  factory :web_push_subscriptions_settings do
    shop_id { SecureRandom.random_number(100) }
    header 'test test test test'
    text 'test test test test'
    safari_website_push_id 'web.com.rees46'
  end
end
