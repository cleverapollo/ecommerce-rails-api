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

    factory :session_with_user do
      user
    end
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

  factory :action do
  end

  factory :mahout_action do
  end

  factory :order do
    uniqid SecureRandom.uuid
    sequence(:date) {|n| Time.current }
  end

  factory :order_item do
  end

  factory :client do
    user

    trait :with_email do
      email { 'test@example.com' }
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
  end

  factory :wear_type_dictionary do
  end

  factory :brand do
    name { 'Apple' }
  end
end