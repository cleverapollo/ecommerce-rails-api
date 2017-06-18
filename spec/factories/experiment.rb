FactoryGirl.define do
  factory :experiment do
    name   { Faker::Lorem.word }
  end
end