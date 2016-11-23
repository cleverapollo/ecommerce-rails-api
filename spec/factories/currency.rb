FactoryGirl.define do
  factory :currency do
    symbol             { Faker::Lorem.word }
    payable            { true }
    exchange_rate      { 1.0 }
    min_payment        { 500 }
    code               { Faker::Lorem.word.downcase }
  end
end
