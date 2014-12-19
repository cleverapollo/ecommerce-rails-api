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
    uniqid sample_session_id

    factory :session_with_user do
      user
    end
  end

  factory :shop do
    uniqid '1234567890'
    secret '0987654321'
    name 'Megashop'
    connection_status do
      { connected_events: {}, connected_recommenders: {} }
    end
    connected_events do
      { }
    end
    connected_recommenders do
      { }
    end
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

  factory :user_shop_relation do
    shop
    user
    uniqid '12345'
  end

  factory :action do
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

  factory :subscription do
    shop
    user
    active true
  end

  factory :audience do
    shop
    user
    sequence(:external_id) {|i| "#{i}" }
    email 'test@example.com'
    active true
    custom_attributes { {} }
  end

  factory :digest_mailing do
    name 'Test'
    subject 'Test'
    template 'Test {{ recommended_item }} {{ unsubscribe_url }}'
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
    shop
    audience
    clicked false
    opened false
  end

  factory :trigger_mail do
    shop
    subscription
    trigger_code 'AbandonedCartEarly'
    trigger_data '{}'
  end
end
