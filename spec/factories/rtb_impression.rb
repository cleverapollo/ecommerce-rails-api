FactoryGirl.define do
  factory :rtb_impression do
    code { SecureRandom.uuid }
    bid_id { rand(1000) }
    ad_id { rand(1000) }
    price { rand(1000) }
    currency 'r.'
    shop_id { rand(1000) }
    item_id { rand(1000) }
    user_id { rand(1000) }
    clicked false
    purchased false
  end
end
