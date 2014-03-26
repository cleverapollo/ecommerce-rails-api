Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

FactoryGirl.define do
  factory :user do
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
    connection_status do
      { connected_events: {}, connected_recommenders: {} }
    end
    connected_events do
      { }
    end
    connected_recommenders do
      { }
    end
  end

  factory :item do
    uniqid '123'
    price 100
    category_uniqid '5'
    is_available true
  end

  factory :user_shop_relation do
    shop
    user
    uniqid '12345'
  end

  factory :action do
  end

  factory :order do
    uniqid SecureRandom.uuid
    sequence(:date) {|n| Time.current }
  end
end
