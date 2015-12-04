FactoryGirl.define do
  factory :yml, class: Nokogiri::XML::Builder do
    before :build do |shop|
      shop[:currencies] = (0..2).map{ build(:yml_currency) }
      shop[:categories] = (0..2).map{ build(:yml_category) }

      shop[:shops] = build_list(:yml_shop, 2).map do |shop|
        shop[:categoryId] = shop[:categories][rand(shop[:categories].count)][:id]
        shop[:currencyId] = shop[:currencies][rand(shop[:currencies].count)][:id]
        shop
      end
    end

    initialize_with do
      puts attributes.inspect

      Nokogiri::XML::Builder.new do |xml|
        xml.root do
          xml.yml_catalog do
            xml.shop do
              xml.name!                attributes[:name]
              xml.company!             attributes[:company]
              xml.url!                 attributes[:url]
              xml.local_delivery_cost! attributes[:local_delivery_cost]

              xml.categories do
                attributes[:categories].each do |category|
                  xml.category!(id: category.id) { category[:name] }
                end
              end

              xml.offers do
                attributes[:offer].each do |offer|
                  xml.offer id: offer[:id], available: offer[:available] do
                    xml.url!         offer[:url]
                    xml.price!       offer[:price]
                    xml.categoryId!  offer[:categoryId]
                    xml.picture!     offer[:picture]
                    xml.name!        offer[:name]
                    xml.description! offer[:description]
                    xml.barcode!     offer[:barcode]
                    xml.typePrefix!  offer[:typePrefix]
                    xml.vendor!      offer[:vendor]
                    xml.vendorCode!  offer[:vendorCode]
                    xml.model!       offer[:model]
                  end
                end
              end

            end
          end
        end
      end
    end
  end

  factory :yml_shop, class: HashWithIndifferentAccess do
    name
    company
    url
    local_delivery_cost

    initialize_with { attributes }
  end

  factory :yml_currency, class: HashWithIndifferentAccess do
    id    { |n| ["RUB", "EUR"][rand(2)] }
    rate  { |n| rand(2).to_s }

    initialize_with { attributes }
  end

  factory :yml_category, class: HashWithIndifferentAccess do
    id
    name

    initialize_with { attributes }
  end

  factory :yml_offer, class: HashWithIndifferentAccess do
    id
    available  { rand(2) > 0 }
    type       { "vendor.model" }
    url
    price      { rand(100500).to_s }
    currencyId { |n| ["RUB", "EUR"][rand(2)] }
    categoryId { |n| n.to_s }
    store      { |n| (rand(2) > 0).to_s }
    pickup     { |n| (rand(2) > 0).to_s }
    delivery   { |n| (rand(2) > 0).to_s }
    vendor     
    model
    description
    country_of_origin

    initialize_with { attributes }

    before :build do |offer|
      offer[:pictures] = (0..2).map{ generate(:picture_url) }
      offer[:currencies] = build_list(:yml_currency, 2)
      offer[:categories] = build_list(:yml_category, 2)
    end
  end
end
