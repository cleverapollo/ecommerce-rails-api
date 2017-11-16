FactoryGirl.define do
  factory :user do
    factory :user_with_session do
      after(:create) do |user, _|
        create_list(:session, 1, user: user)
      end
    end
  end

  factory :session do
    code '12345'
    updated_at { Date.current }

    factory :session_with_user do
      user
    end

    trait :with_user do
      user
    end

    trait :uniq do
      code
    end
  end

  factory :recommender_block do
    name { Faker::Lorem.word }
    code { SecureRandom.uuid }
  end

  factory :invalid_email do
  end

  factory :brand_campaign do
    brand             { Faker::Lorem.word }
    downcase_brand    { brand.downcase }
    campaign_launched true
  end

  factory :brand_campaign_statistic do
  end

  factory :brand_campaign_shop do
  end

  factory :action_cl do
    current_session_code { SecureRandom.uuid }
    useragent { Faker::Lorem.word }
    referer { Faker::Lorem.word }
    date { Date.current }
  end

  factory :mahout_action do
  end

  factory :order do
    uniqid { SecureRandom.uuid }
    sequence(:date) {|n| Time.current }
  end

  factory :order_item do
  end

  factory :client do
    user

    trait :with_email do
      email { 'test@rees46demo.com' }
    end
  end

  factory :interaction do
    shop
    item
    code 1
  end

  factory :promotion do
    brand { 'apple' }
    categories { ['телефоны', 'планшеты'] }
  end

  factory :item_category do
    external_id { SecureRandom.uuid }
    shop
  end

  factory :wear_type_dictionary do
  end

  factory :brand do
    name { 'Apple' }
  end

  factory :shop_location do
    external_id { SecureRandom.uuid }
    external_type { 'city' }
    name { Faker::Lorem.word }
  end

  factory :subscriptions_settings do
    header { Faker::Lorem.word }
    text { Faker::Lorem.word }
    button { Faker::Lorem.word }
    agreement { Faker::Lorem.word }
    popup_type { 0 }
    timer { 90 }
    pager { 0 }
    cursor { 50 }
  end
end
