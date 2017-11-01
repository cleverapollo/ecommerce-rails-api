FactoryGirl.define do
  factory :visit do
  end

  factory :visit_cl do
    current_session_code { SecureRandom.uuid }
    url 'https://test.com'
    useragent 'test'
    ip '127.0.0.1'
  end
end
