FactoryGirl.define do
  factory :rtb_impression do
    code
    bid_id
    ad_id
    price
    currency
    shop_id
    item_id
    user_id
    clicked
    purchased
  end
end
