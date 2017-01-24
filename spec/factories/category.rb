FactoryGirl.define do
  factory :category do
    code { SecureRandom.uuid }
  end
end
