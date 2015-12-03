FactoryGirl.define do
  factory :plan do
    name
    plan_type 'free'
    orders_min 0
    orders_max 100
  end
end
