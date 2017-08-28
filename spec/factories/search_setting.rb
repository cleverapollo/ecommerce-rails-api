FactoryGirl.define do
  factory :search_setting do
    landing_page Faker::Internet.http_url
  end
end
