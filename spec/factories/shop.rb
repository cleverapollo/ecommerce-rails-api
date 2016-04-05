FactoryGirl.define do
  factory :shop do
    url
    yml_file_url
    category_id 5
    active true
    customer nil
    restricted false
    use_brb false
    connected_events_last_track       {{}}
    connected_recommenders_last_track {{}}
    uniqid
    name

    connection_status_last_track do
      {
        connected_events_last_track: {},
        connected_recommenders_last_track: {}
      }
    end

    trait(:with_yml)           { yml_file_url "http://example.com/shop.xml" }
    trait(:without_yml)        { yml_file_url nil }
    trait(:with_yml_errors)    { yml_errors 5 }
    trait(:without_yml_errors) { yml_errors 0 }

    trait :with_imported_yml do
      with_yml
      yml_loaded true
      without_yml_errors
    end

    trait(:active)    { active true }
    trait(:connected) { connected true}
  end

  factory :shop_metric do
  end

  factory :shop_xml, class: Hash do
    name 
    company
    url
    local_delivery_cost
    currencies
  end
end
