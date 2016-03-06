FactoryGirl.define do
  factory :customer do
    email { Faker::Internet.email }
    balance 0
  end
end
