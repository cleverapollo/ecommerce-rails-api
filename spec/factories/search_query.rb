FactoryGirl.define do
  factory :search_query do

    user_id { SecureRandom.random_number(100) }
    shop_id { SecureRandom.random_number(100) }
    date { Date.current }
    query { Faker::Lorem.word }

  end


end
