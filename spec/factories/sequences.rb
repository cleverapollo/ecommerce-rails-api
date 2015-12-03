FactoryGirl.define do
  sequence(:id)                  { |n| n }
  sequence(:name)                { |n| "name #{n}" }
  sequence(:company)             { |n| "company #{n}" }
  sequence(:email)               { |n| "person#{n}@example.com" }
  sequence(:uniqid)              { |n| SecureRandom.hex }
  sequence(:secret)              { |n| SecureRandom.hex }
  sequence(:url)                 { |n| "http://example_#{n}.com" }
  sequence(:yml_file_url)        { |n| "http://example_#{n}.com/path/to/yml.xml" }
  sequence(:local_delivery_cost) { rand(100) + 100 }
  sequence(:picture_url)         { |n| "http://example_cdn.com/path/to/image/#{n}.jpg" }
  sequence(:vendor)              { |n| "vendor #{n}" }
  sequence(:model)               { |n| "model #{n}" }
  sequence(:description)         { |n| "description #{n}" }
  sequence(:country_of_origin)   { |n| "Russia" }
end
