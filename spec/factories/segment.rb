FactoryGirl.define do
  factory :segment do
    name { Faker::Lorem.word }
    segment_type Segment::TYPE_CALCULATE
  end
end
