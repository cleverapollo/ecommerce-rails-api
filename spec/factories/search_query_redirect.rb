FactoryGirl.define do
  factory :search_query_redirect do
    query { Faker::Lorem.word }
    redirect_link { Faker::Internet.uri('http') }
  end
end