Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

FactoryGirl.define do
  factory :user do
    factory :user_with_session do
      after(:create) do |user, _|
        create_list(:session, 1, user: user)
      end
    end
  end

  factory :session do
    code sample_session_id

    factory :session_with_user do
      user
    end
  end

  factory :shop do
    uniqid { SecureRandom.hex }
    secret { SecureRandom.hex }
    name 'Megashop'
    connection_status_last_track  do
      { connected_events_last_track: {}, connected_recommenders_last_track: {} }
    end
    connected_events_last_track do
      { }
    end
    connected_recommenders_last_track do
      { }
    end
    yml_file_url 'http://example.com'
    trait :without_yml do
      yml_file_url nil
    end
    url 'http://example.com'
    category_id 5
    active true
    restricted false
  end

  factory :item do
    sequence(:uniqid) {|i| "#{i}" }
    price 100
    categories '{5}'
    is_available true
    ignored false
    url 'http://example.com/item/123'
    image_url 'http://example.com/item/123.jpg'
    name 'test'
    widgetable true
    description ''
  end

  factory :action do
  end

  factory :mahout_action do
  end

  factory :order do
    uniqid SecureRandom.uuid
    sequence(:date) {|n| Time.current }
  end

  factory :mailers_digest_params, class: HashWithIndifferentAccess do
    skip_create

    initialize_with { attributes }
  end

  factory :mailing do
    shop
    sequence(:token) {|n| SecureRandom.hex(8) }
    delivery_settings do
      {
        send_from: 'tester <tester@tester.ru>'
      }
    end
    items do
      [
        { id: 123 }
      ]
    end
  end

  factory :mailing_batch do
    users { [ id: 1 ] }
  end

  factory :digest_mailing do
    name 'Test'
    subject 'Test'
    template 'Test {{ recommended_item }} {{ footer }}'
    item_template '{{ name }}{{ url }}'
    state 'started'
  end

  factory :digest_mailing_setting do
    on true
    sender 'test@test.te'
  end

  factory :digest_mailing_batch do
    start_id 1
    end_id 2
  end

  factory :digest_mail do
  end

  factory :trigger_mailing do
    trigger_type 'abandoned_cart'
    subject 'test'
    template 'Test {{ recommended_item }} {{ footer }}'
    item_template '{{ name }}{{ url }}'
  end

  factory :trigger_mail do
    trigger_data do
      { test: 123 }
    end
  end

  factory :client do
    user
  end

  factory :mailings_settings do
    shop
    send_from 'test@example.com'
  end

  factory :interaction do
    shop
    item
    code 1
  end
end
