FactoryGirl.define do
  factory :profile_event do
    shop
    user
  end

  factory :profile_event_cl do
    shop
    current_session_code SecureRandom.uuid
    date { Date.current }
    created_at { Time.now }
  end
end
