FactoryGirl.define do
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

  factory :mailings_settings do
    shop
    send_from 'test@example.com'
  end

  factory :mailers_digest_params, class: HashWithIndifferentAccess do
    skip_create

    initialize_with { attributes }
  end
end