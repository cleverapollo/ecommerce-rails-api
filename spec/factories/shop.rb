FactoryGirl.define do
  factory :shop do
    url
    yml_file_url
    category_id 5
    active true
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

    trait :without_yml do
      yml_file_url nil
    end
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
