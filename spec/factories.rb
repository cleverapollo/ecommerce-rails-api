Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

FactoryGirl.define do
  factory :user do
    ab_testing_group 2

    factory :user_with_session do
      after(:create) do |user, _|
        create_list(:session, 1, user: user)
      end
    end
  end

  factory :session do
    uniqid sample_session_id

    factory :session_with_user do
      user
    end
  end

  factory :shop do
    uniqid '1234567890'
    name 'Megashop'
  end

  factory :item do
    uniqid '123'
    price 100
    category_uniqid '5'
    is_available true
  end
end
