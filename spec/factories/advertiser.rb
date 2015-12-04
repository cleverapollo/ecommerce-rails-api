FactoryGirl.define do
  factory :advertiser do
    first_name   { Faker::Lorem.word }
    last_name    { Faker::Lorem.word }
    mobile_phone { Faker::PhoneNumberFR.phone_number }
    work_phone   { Faker::PhoneNumberFR.phone_number }
    company      { Faker::Company.name }
    website      { Faker::Internet.http_url }
    country      { Faker::Address.country_code }
    city         { Faker::Address.city }
    email        { Faker::Internet.email }
  end
end