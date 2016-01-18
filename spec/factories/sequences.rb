FactoryGirl.define do
  sequence(:id)                  { |n| n }
  sequence(:code)                { |n| n }
  sequence(:name)                { |n| "name #{n}" }
  sequence(:company)             { |n| "company #{n}" }
  sequence(:brand)               { |n| "brand #{n}" }
  sequence(:type_prefix)         { |n| "type.prefiix #{n}" }
  sequence(:barcode)             { |n| SecureRandom.hex }
  sequence(:size)                { |n| rand(50) }
  sequence(:gender)              { |n| ['f','m'][rand(2)] }
  sequence(:vendor_code)         { |n| SecureRandom.hex }
  sequence(:wear_type)           { Rees46ML::Fashion::TYPES[rand(Rees46ML::Fashion::TYPES.size)] }
  sequence(:feature)             { Rees46ML::Fashion::FEATURES[rand(Rees46ML::Fashion::FEATURES.size)] }
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
