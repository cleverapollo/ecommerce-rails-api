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
  end
end
