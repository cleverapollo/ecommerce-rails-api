module Rees46ML
  class Parser < Nokogiri::XML::SAX::Document
    include AASM

    aasm do
      state :root, initial: true
      state :yml_catalog
      state :shop
      state :name
      state :group_id
      state :platform
      state :sales_notes
      state :phone
      state :market_category
      state :company
      state :version
      state :agency
      state :email
      state :cpa
      state :url
      state :weight
      state :currencies
      state :currency
      state :categories
      state :category
      state :local_delivery_cost
      state :offers
      state :offer
      state :feature
      state :accessories
      state :accessory
      state :locations
      state :location
      state :price
      state :price_margin
      state :baseprice
      state :ordering_time
      state :ordering
      state :manufacturer_warranty
      state :currency_id
      state :category_id
      state :picture
      state :delivery_options
      state :option
      state :barcode
      state :store
      state :pickup
      state :ignored
      state :param
      state :child
      state :fashion
      state :cosmetic
      state :fmcg
      state :jewelry
      state :ring_sizes
      state :ring_size
      state :bracelet_sizes
      state :bracelet_size
      state :chain_sizes
      state :chain_size
      state :jewelry_metal
      state :jewelry_color
      state :jewelry_gem
      state :pets
      state :pet_age
      state :pet_size
      state :pet_type
      state :breed
      state :auto
      state :compatibility
      state :vds
      state :periodic
      state :skin
      state :hair
      state :nail
      state :polish_color
      state :perfume
      state :aroma
      state :professional
      state :part
      state :type
      state :condition
      state :hypoallergenic
      state :age
      state :gender
      state :sizes
      state :size
      state :min
      state :max
      state :oldprice
      state :delivery
      state :type_prefix
      state :vendor
      state :vendor_code
      state :model
      state :description
      state :manufacturer_warranty
      state :country_of_origin
      state :author
      state :publisher
      state :series
      state :year
      state :isbn
      state :volumes
      state :volume
      state :value
      state :part
      state :language
      state :binding
      state :page_extent
      state :downloadable
      state :performed_by
      state :performance_type
      state :storage
      state :format
      state :recording_length
      state :artist
      state :title
      state :adult
      state :media
      state :starring
      state :director
      state :original_name
      state :country
      state :world_region
      state :region
      state :days
      state :data_tour
      state :hotel_stars
      state :room
      state :meal
      state :included
      state :transport
      state :place
      state :hall
      state :hall_part
      state :date
      state :is_premiere
      state :is_kids
      state :seasonality

      event :start_yml_catalog do
        transitions from: :root, to: :yml_catalog
      end

      event :end_yml_catalog do
        transitions from: :yml_catalog, to: :root
      end

      event :start_shop do
        transitions from: :yml_catalog, to: :shop
      end

      event :end_shop do
        transitions from: :shop, to: :yml_catalog
      end

      event :start_name do
        transitions from: :shop, to: :name
        transitions from: :offer, to: :name
      end

      event :end_name do
        transitions from: :name, to: :shop,  guard: :in_shop?
        transitions from: :name, to: :offer, guard: :in_offer?
      end

      event :start_company do
        transitions from: :shop, to: :company
      end

      event :end_company do
        transitions from: :company, to: :shop
      end

      event :start_phone do
        transitions from: :shop,  to: :phone
      end

      event :end_phone do
        transitions from: :phone, to: :shop
      end

      event :start_platform do
        transitions from: :shop,  to: :platform
      end

      event :end_platform do
        transitions from: :platform, to: :shop
      end

      event :start_price_margin do
        transitions from: :offer,  to: :price_margin
      end

      event :end_price_margin do
        transitions from: :price_margin, to: :offer
      end

      event :start_version do
        transitions from: :shop,  to: :version
      end

      event :end_version do
        transitions from: :version, to: :shop
      end

      event :start_agency do
        transitions from: :shop,  to: :agency
      end

      event :end_agency do
        transitions from: :agency, to: :shop
      end

      event :start_adult do
        transitions from: :shop,  to: :adult
        transitions from: :offer, to: :adult
      end

      event :end_adult do
        transitions from: :adult, to: :shop,  guard: :in_shop?
        transitions from: :adult, to: :offer, guard: :in_offer?
      end

      event :start_email do
        transitions from: :shop,  to: :email
      end

      event :end_email do
        transitions from: :email, to: :shop
      end

      event :start_cpa do
        transitions from: :shop, to: :cpa
        transitions from: :offer, to: :cpa
      end

      event :end_cpa do
        transitions from: :cpa, to: :shop, guard: :in_shop?
        transitions from: :cpa, to: :offer, guard: :in_offer?
      end

      event :start_weight do
        transitions from: :offer,  to: :weight
      end

      event :end_weight do
        transitions from: :weight, to: :offer
      end

      event :start_ordering_time do
        transitions from: :offer, to: :ordering_time
      end

      event :end_ordering_time do
        transitions from: :ordering_time, to: :offer
      end

      event :start_ordering do
        transitions from: :ordering_time, to: :ordering
      end

      event :end_ordering do
        transitions from: :ordering, to: :ordering_time
      end

      event :start_url do
        transitions from: :shop,  to: :url
        transitions from: :offer, to: :url
      end

      event :end_url do
        transitions from: :url, to: :offer, guard: :in_offer?
        transitions from: :url, to: :shop,  guard: :in_shop?
      end

      event :start_delivery_options do
        transitions from: :shop,  to: :delivery_options
        transitions from: :offer, to: :delivery_options
      end

      event :end_delivery_options do
        transitions from: :delivery_options, to: :offer, guard: :in_offer?
        transitions from: :delivery_options, to: :shop,  guard: :in_shop?
      end

      event :start_option do
        transitions from: :delivery_options, to: :option
      end

      event :end_option do
        transitions from: :option, to: :delivery_options
      end

      event :start_group_id do
        transitions from: :offer,  to: :group_id
      end

      event :end_group_id do
        transitions from: :group_id, to: :offer
      end

      event :start_market_category do
        transitions from: :offer,  to: :market_category
      end

      event :end_market_category do
        transitions from: :market_category, to: :offer
      end

      event :start_sales_notes do
        transitions from: :offer,  to: :sales_notes
      end

      event :end_sales_notes do
        transitions from: :sales_notes, to: :offer
      end

      event :start_currencies do
        transitions from: :shop, to: :currencies
      end

      event :end_currencies do
        transitions from: :currencies, to: :shop
      end

      event :start_currency do
        transitions from: :currencies, to: :currency
      end

      event :end_currency do
        transitions from: :currency, to: :currencies
      end

      event :start_categories do
        transitions from: :shop, to: :categories
      end

      event :end_categories do
        transitions from: :categories, to: :shop
      end

      event :start_category do
        transitions from: :categories, to: :category
      end

      event :end_category do
        transitions from: :category, to: :categories
      end

      event :start_local_delivery_cost do
        transitions from: :shop,  to: :local_delivery_cost
        transitions from: :offer, to: :local_delivery_cost
      end

      event :end_local_delivery_cost do
        transitions from: :local_delivery_cost, to: :shop,  guard: :in_shop?
        transitions from: :local_delivery_cost, to: :offer, guard: :in_offer?
      end

      event :start_offers do
        transitions from: :shop, to: :offers
      end

      event :end_offers do
        transitions from: :offers, to: :shop
      end

      event :start_offer do
        transitions from: :offers, to: :offer
      end

      event :end_offer do
        transitions from: :offer, to: :offers
      end

      event :start_price do
        transitions from: :offer,    to: :price
        transitions from: :volume,   to: :price
        transitions from: :location, to: :price
      end

      event :end_price do
        transitions from: :price, to: :offer,    guard: :in_offer?
        transitions from: :price, to: :volume,   guard: :in_volume?
        transitions from: :price, to: :location, guard: :in_location?
      end

      event :start_baseprice do
        transitions from: :offer, to: :baseprice
      end

      event :end_baseprice do
        transitions from: :baseprice, to: :offer
      end

      event :start_currency_id do
        transitions from: :offer, to: :currency_id
      end

      event :end_currency_id do
        transitions from: :currency_id, to: :offer
      end

      event :start_category_id do
        transitions from: :offer, to: :category_id
      end

      event :end_category_id do
        transitions from: :category_id, to: :offer
      end

      event :start_seasonality do
        transitions from: :offer, to: :seasonality
      end

      event :end_seasonality do
        transitions from: :seasonality, to: :offer
      end

      event :start_picture do
        transitions from: :offer, to: :picture
      end

      event :end_picture do
        transitions from: :picture, to: :offer
      end

      event :start_barcode do
        transitions from: :offer, to: :barcode
      end

      event :end_barcode do
        transitions from: :barcode, to: :offer
      end

      event :start_oldprice do
        transitions from: :offer, to: :oldprice
      end

      event :end_oldprice do
        transitions from: :oldprice, to: :offer
      end

      event :start_store do
        transitions from: :shop,  to: :store
        transitions from: :offer, to: :store
      end

      event :end_store do
        transitions from: :store, to: :shop,  guard: :in_shop?
        transitions from: :store, to: :offer, guard: :in_offer?
      end

      event :start_child do
        transitions from: :offer, to: :child
      end

      event :end_child do
        transitions from: :child, to: :offer
      end

      event :start_fmcg do
        transitions from: :offer, to: :fmcg
      end

      event :end_fmcg do
        transitions from: :fmcg, to: :offer
      end

      event :start_pets do
        transitions from: :offer, to: :pets
      end

      event :end_pets do
        transitions from: :pets, to: :offer
      end

      event :start_auto do
        transitions from: :offer, to: :auto
      end

      event :end_auto do
        transitions from: :auto, to: :offer
      end

      event :start_jewelry do
        transitions from: :offer, to: :jewelry
      end

      event :end_jewelry do
        transitions from: :jewelry, to: :offer
      end

      event :start_cosmetic do
        transitions from: :offer, to: :cosmetic
      end

      event :end_cosmetic do
        transitions from: :cosmetic, to: :offer
      end

      event :start_periodic do
        transitions from: :cosmetic, to: :periodic
        transitions from: :fmcg,     to: :periodic
        transitions from: :auto,     to: :periodic
        transitions from: :pets,     to: :periodic
      end

      event :end_periodic do
        transitions from: :periodic, to: :cosmetic, guard: :in_cosmetic?
        transitions from: :periodic, to: :fmcg,    guard: :in_fmcg?
        transitions from: :periodic, to: :auto,    guard: :in_auto?
        transitions from: :periodic, to: :pets,    guard: :in_pets?
      end

      event :start_compatibility do
        transitions from: :auto, to: :compatibility
      end

      event :end_compatibility do
        transitions from: :compatibility, to: :auto, guard: :in_auto?
      end

      event :start_vds do
        transitions from: :auto, to: :vds
      end

      event :end_vds do
        transitions from: :vds, to: :auto, guard: :in_auto?
      end

      event :start_fashion do
        transitions from: :offer, to: :fashion
      end

      event :end_fashion do
        transitions from: :fashion, to: :offer
      end

      event :start_feature do
        transitions from: :fashion, to: :feature
      end

      event :end_feature do
        transitions from: :feature, to: :fashion, guard: :in_fashion?
      end

      event :start_locations do
        transitions from: :shop,  to: :locations
        transitions from: :offer, to: :locations
      end

      event :end_locations do
        transitions from: :locations, to: :shop,  guard: :in_shop?
        transitions from: :locations, to: :offer, guard: :in_offer?
      end

      event :start_location do
        transitions from: :locations, to: :location
      end

      event :end_location do
        transitions from: :location, to: :locations
      end

      event :start_accessories do
        transitions from: :offer, to: :accessories, guard: :in_offer?
      end

      event :end_accessories do
        transitions from: :accessories, to: :offer, guard: :in_offer?
      end

      event :start_accessory do
        transitions from: :accessories, to: :accessory
      end

      event :end_accessory do
        transitions from: :accessory, to: :accessories
      end

      event :start_hypoallergenic do
        transitions from: :cosmetic, to: :hypoallergenic
        transitions from: :fmcg,    to: :hypoallergenic
      end

      event :end_hypoallergenic do
        transitions from: :hypoallergenic, to: :cosmetic, guard: :in_cosmetic?
        transitions from: :hypoallergenic, to: :fmcg,    guard: :in_fmcg?
      end


      event :start_skin do
        transitions from: :cosmetic, to: :skin
      end

      event :end_skin do
        transitions from: :skin, to: :cosmetic
      end

      event :start_hair do
        transitions from: :cosmetic, to: :hair
      end

      event :end_hair do
        transitions from: :hair, to: :cosmetic
      end

      event :start_nail do
        transitions from: :cosmetic, to: :nail
      end

      event :end_nail do
        transitions from: :nail, to: :cosmetic
      end

      event :start_polish_color do
        transitions from: :nail, to: :polish_color
      end

      event :end_polish_color do
        transitions from: :polish_color, to: :nail
      end

      event :start_perfume do
        transitions from: :cosmetic, to: :perfume
      end

      event :end_perfume do
        transitions from: :perfume, to: :cosmetic
      end

      event :start_professional do
        transitions from: :cosmetic, to: :professional
      end

      event :end_professional do
        transitions from: :professional, to: :cosmetic
      end

      event :start_condition do
        transitions from: :skin, to: :condition
        transitions from: :hair, to: :condition
      end

      event :end_condition do
        transitions from: :condition, to: :skin, guard: :in_skin?
        transitions from: :condition, to: :hair, guard: :in_hair?
      end

      event :start_gender do
        transitions from: :child,    to: :gender
        transitions from: :fashion,  to: :gender
        transitions from: :cosmetic, to: :gender
        transitions from: :jewelry, to: :gender
      end

      event :end_gender do
        transitions from: :gender, to: :child,    guard: :in_child?
        transitions from: :gender, to: :fashion,  guard: :in_fashion?
        transitions from: :gender, to: :cosmetic, guard: :in_cosmetic?
        transitions from: :gender, to: :jewelry, guard: :in_jewelry?
      end

      event :start_type do
        transitions from: :child,   to: :type
        transitions from: :fashion, to: :type
        transitions from: :skin, to: :type
        transitions from: :hair, to: :type
        transitions from: :nail, to: :type
      end

      event :end_type do
        transitions from: :type, to: :child,   guard: :in_child?
        transitions from: :type, to: :fashion, guard: :in_fashion?
        transitions from: :type, to: :skin, guard: :in_skin?
        transitions from: :type, to: :hair, guard: :in_hair?
        transitions from: :type, to: :nail, guard: :in_nail?
      end

      event :start_aroma do
        transitions from: :perfume,   to: :aroma
      end

      event :end_aroma do
        transitions from: :aroma,   to: :perfume
      end

      event :start_pet_size do
        transitions from: :pets,   to: :pet_size
      end

      event :end_pet_size do
        transitions from: :pet_size,   to: :pets
      end

      event :start_pet_type do
        transitions from: :pets,   to: :pet_type
      end

      event :end_pet_type do
        transitions from: :pet_type,   to: :pets
      end

      event :start_pet_age do
        transitions from: :pets,   to: :pet_age
      end

      event :end_pet_age do
        transitions from: :pet_age,   to: :pets
      end

      event :start_breed do
        transitions from: :pets,   to: :breed
      end

      event :end_breed do
        transitions from: :breed,   to: :pets
      end

      event :start_age do
        transitions from: :offer,   to: :age
        transitions from: :child,   to: :age
        transitions from: :pets,   to: :age
      end

      event :end_age do
        transitions from: :age, to: :offer,   guard: :in_offer?
        transitions from: :age, to: :child,   guard: :in_child?
        transitions from: :age, to: :pets,   guard: :in_pets?
      end

      event :start_min do
        transitions from: :age, to: :min
      end

      event :end_min do
        transitions from: :min, to: :age
      end

      event :start_max do
        transitions from: :age, to: :max
      end

      event :end_max do
        transitions from: :max, to: :age
      end

      event :start_sizes do
        transitions from: :fashion, to: :sizes
      end

      event :end_sizes do
        transitions from: :sizes, to: :fashion, guard: :in_fashion?
      end

      event :start_size do
        transitions from: :sizes, to: :size
      end

      event :end_size do
        transitions from: :size, to: :sizes
      end

      event :start_jewelry_color do
        transitions from: :jewelry, to: :jewelry_color
      end

      event :end_jewelry_color do
        transitions from: :jewelry_color, to: :jewelry
      end

      event :start_jewelry_metal do
        transitions from: :jewelry, to: :jewelry_metal
      end

      event :end_jewelry_metal do
        transitions from: :jewelry_metal, to: :jewelry
      end

      event :start_jewelry_gem do
        transitions from: :jewelry, to: :jewelry_gem
      end

      event :end_jewelry_gem do
        transitions from: :jewelry_gem, to: :jewelry
      end

      event :start_ring_sizes do
        transitions from: :jewelry, to: :ring_sizes
      end

      event :end_ring_sizes do
        transitions from: :ring_sizes, to: :jewelry
      end

      event :start_bracelet_sizes do
        transitions from: :jewelry, to: :bracelet_sizes
      end

      event :end_bracelet_sizes do
        transitions from: :bracelet_sizes, to: :jewelry
      end

      event :start_chain_sizes do
        transitions from: :jewelry, to: :chain_sizes
      end

      event :end_chain_sizes do
        transitions from: :chain_sizes, to: :jewelry
      end

      event :start_ring_size do
        transitions from: :ring_sizes, to: :ring_size
      end

      event :end_ring_size do
        transitions from: :ring_size, to: :ring_sizes
      end

      event :start_bracelet_size do
        transitions from: :bracelet_sizes, to: :bracelet_size
      end

      event :end_bracelet_size do
        transitions from: :bracelet_size, to: :bracelet_sizes
      end

      event :start_chain_size do
        transitions from: :chain_sizes, to: :chain_size
      end

      event :end_chain_size do
        transitions from: :chain_size, to: :chain_sizes
      end


      event :start_pickup do
        transitions from: :shop, to: :pickup
        transitions from: :offer, to: :pickup
      end

      event :end_pickup do
        transitions from: :pickup, to: :offer, guard: :in_offer?
        transitions from: :pickup, to: :shop,  guard: :in_shop?
      end

      event :start_ignored do
        transitions from: :offer, to: :ignored
      end

      event :end_ignored do
        transitions from: :ignored, to: :offer
      end

      event :start_param do
        transitions from: :offer, to: :param
      end

      event :end_param do
        transitions from: :param, to: :offer
      end

      event :start_delivery do
        transitions from: :offer, to: :delivery
        transitions from: :shop,  to: :delivery
      end

      event :end_delivery do
        transitions from: :delivery, to: :offer, guard: :in_offer?
        transitions from: :delivery, to: :shop,  guard: :in_shop?
      end

      event :start_type_prefix do
        transitions from: :offer, to: :type_prefix
      end

      event :end_type_prefix do
        transitions from: :type_prefix, to: :offer
      end

      event :start_vendor do
        transitions from: :offer, to: :vendor
      end

      event :end_vendor do
        transitions from: :vendor, to: :offer
      end

      event :start_vendor_code do
        transitions from: :offer, to: :vendor_code
      end

      event :end_vendor_code do
        transitions from: :vendor_code, to: :offer
      end

      event :start_model do
        transitions from: :offer, to: :model
      end

      event :end_model do
        transitions from: :model, to: :offer
      end

      event :start_description do
        transitions from: :offer, to: :description
      end

      event :end_description do
        transitions from: :description, to: :offer
      end

      event :start_manufacturer_warranty do
        transitions from: :offer, to: :manufacturer_warranty
      end

      event :end_manufacturer_warranty do
        transitions from: :manufacturer_warranty, to: :offer
      end

      event :start_country_of_origin do
        transitions from: :offer, to: :country_of_origin
      end

      event :end_country_of_origin do
        transitions from: :country_of_origin, to: :offer
      end

      event :start_author do
        transitions from: :offer, to: :author
      end

      event :end_author do
        transitions from: :author, to: :offer
      end

      event :start_publisher do
        transitions from: :offer, to: :publisher
      end

      event :end_publisher do
        transitions from: :publisher, to: :offer
      end

      event :start_series do
        transitions from: :offer, to: :series
      end

      event :end_series do
        transitions from: :series, to: :offer
      end

      event :start_year do
        transitions from: :offer, to: :year
      end

      event :end_year do
        transitions from: :year, to: :offer
      end

      event :start_isbn do
        transitions from: :offer, to: :isbn
      end

      event :end_isbn do
        transitions from: :isbn, to: :offer
      end

      event :start_volumes do
        transitions from: :cosmetic, to: :volumes
        transitions from: :fmcg, to: :volumes
      end

      event :end_volumes do
        transitions from: :volumes, to: :cosmetic,  guard: :in_cosmetic?
        transitions from: :volumes, to: :fmcg,      guard: :in_fmcg?
      end

      event :start_volume do
        transitions from: :offer,   to: :volume
        transitions from: :volumes, to: :volume
      end

      event :end_volume do
        transitions from: :volume, to: :offer,   guard: :in_offer?
        transitions from: :volume, to: :volumes, guard: :in_volumes?
      end

      event :start_value do
        transitions from: :volume, to: :value
      end

      event :end_value do
        transitions from: :value, to: :volume
      end

      event :start_part do
        transitions from: :offer, to: :part
        transitions from: :skin, to: :part
      end

      event :end_part do
        transitions from: :part, to: :offer, guard: :in_offer?
        transitions from: :part, to: :skin, guard: :in_skin?
      end

      event :start_language do
        transitions from: :offer, to: :language
      end

      event :end_language do
        transitions from: :language, to: :offer
      end

      event :start_binding do
        transitions from: :offer, to: :binding
      end

      event :end_binding do
        transitions from: :binding, to: :offer
      end

      event :start_page_extent do
        transitions from: :offer, to: :page_extent
      end

      event :end_page_extent do
        transitions from: :page_extent, to: :offer
      end

      event :start_downloadable do
        transitions from: :offer, to: :downloadable
      end

      event :end_downloadable do
        transitions from: :downloadable, to: :offer
      end

      event :start_performed_by do
        transitions from: :offer, to: :performed_by
      end

      event :end_performed_by do
        transitions from: :performed_by, to: :offer
      end

      event :start_performance_type do
        transitions from: :offer, to: :performance_type
      end

      event :end_performance_type do
        transitions from: :performance_type, to: :offer
      end

      event :start_storage do
        transitions from: :offer, to: :storage
      end

      event :end_storage do
        transitions from: :storage, to: :offer
      end

      event :start_format do
        transitions from: :offer, to: :format
      end

      event :end_format do
        transitions from: :format, to: :offer
      end

      event :start_recording_length do
        transitions from: :offer, to: :recording_length
      end

      event :end_recording_length do
        transitions from: :recording_length, to: :offer
      end

      event :start_artist do
        transitions from: :offer, to: :artist
      end

      event :end_artist do
        transitions from: :artist, to: :offer
      end

      event :start_title do
        transitions from: :offer, to: :title
      end

      event :end_title do
        transitions from: :title, to: :offer
      end

      event :start_media do
        transitions from: :offer, to: :media
      end

      event :end_media do
        transitions from: :media, to: :offer
      end

      event :start_starring do
        transitions from: :offer, to: :starring
      end

      event :end_starring do
        transitions from: :starring, to: :offer
      end

      event :start_director do
        transitions from: :offer, to: :director
      end

      event :end_director do
        transitions from: :director, to: :offer
      end

      event :start_original_name do
        transitions from: :offer, to: :original_name
      end

      event :end_original_name do
        transitions from: :original_name, to: :offer
      end

      event :start_country do
        transitions from: :offer, to: :country
      end

      event :end_country do
        transitions from: :country, to: :offer
      end

      event :start_world_region do
        transitions from: :offer, to: :world_region
      end

      event :end_world_region do
        transitions from: :world_region, to: :offer
      end

      event :start_region do
        transitions from: :offer, to: :region
      end

      event :end_region do
        transitions from: :region, to: :offer
      end

      event :start_days do
        transitions from: :offer, to: :days
      end

      event :end_days do
        transitions from: :days, to: :offer
      end

      event :start_data_tour do
        transitions from: :offer, to: :data_tour
      end

      event :end_data_tour do
        transitions from: :data_tour, to: :offer
      end

      event :start_hotel_stars do
        transitions from: :offer, to: :hotel_stars
      end

      event :end_hotel_stars do
        transitions from: :hotel_stars, to: :offer
      end

      event :start_room do
        transitions from: :offer, to: :room
      end

      event :end_room do
        transitions from: :room, to: :offer
      end

      event :start_meal do
        transitions from: :offer, to: :meal
      end

      event :end_meal do
        transitions from: :meal, to: :offer
      end

      event :start_included do
        transitions from: :offer, to: :included
      end

      event :end_included do
        transitions from: :included, to: :offer
      end

      event :start_transport do
        transitions from: :offer, to: :transport
      end

      event :end_transport do
        transitions from: :transport, to: :offer
      end

      event :start_place do
        transitions from: :offer, to: :place
      end

      event :end_place do
        transitions from: :place, to: :offer
      end

      event :start_hall do
        transitions from: :offer, to: :hall
      end

      event :end_hall do
        transitions from: :hall, to: :offer
      end

      event :start_hall_part do
        transitions from: :offer, to: :hall_part
      end

      event :end_hall_part do
        transitions from: :hall_part, to: :offer
      end

      event :start_date do
        transitions from: :offer, to: :date
      end

      event :end_date do
        transitions from: :date, to: :offer
      end

      event :start_is_premiere do
        transitions from: :offer, to: :is_premiere
      end

      event :end_is_premiere do
        transitions from: :is_premiere, to: :offer
      end

      event :start_is_kids do
        transitions from: :offer, to: :is_kids
      end

      event :end_is_kids do
        transitions from: :is_kids, to: :offer
      end
    end

    aasm.states.map(&:name).each do |state_name|
      define_method "in_#{ state_name }?" do
        path[-2] == state_name.to_s
      end
    end

    attr_reader :states

    def initialize(logger, &consumer)
      @consumer = consumer
      @logger = logger
    end

    def start_element(name, attrs = [])
      debug "> #{ name }"

      path.push name
      event_name = underscore("start_#{ name }")

      if aasm.may_fire_event? event_name.to_sym
        case name
        when "shop"
          self.current_element = Rees46ML::Shop.new
        when "offers"
          # pop shop after offers section
          @consumer.call self.current_element
          stack.pop
        when "currency"
          self.current_element = Rees46ML::Currency.new
        when "option"
          self.current_element = Rees46ML::DeliveryOption.new
        when "category"
          self.current_element = Rees46ML::Category.new
        when "location"
          self.current_element = Rees46ML::ShopLocation.new if self.current_element.is_a?(Rees46ML::Shop)
          self.current_element = Rees46ML::Location.new if self.current_element.is_a?(Rees46ML::Offer)
        when "accessory"
          self.current_element = Rees46ML::Accessory.new
        when "price"
          self.current_element = Rees46ML::Price.new if in_location?
        when "child"
          self.current_element = Rees46ML::Child.new
        when "fashion"
          self.current_element = Rees46ML::Fashion.new
        when "cosmetic"
          self.current_element = Rees46ML::Cosmetic.new
        when "fmcg"
          self.current_element = Rees46ML::Fmcg.new
        when "jewelry"
          self.current_element = Rees46ML::Jewelry.new
        when "pets"
          self.current_element = Rees46ML::Pets.new
        when "volume"
          self.current_element = Rees46ML::CosmeticVolume.new if in_cosmetic?
          self.current_element = Rees46ML::FmcgVolume.new if in_fmcg?
        when "age"
          self.current_element = Rees46ML::Age.new if in_offer?
          self.current_element = Rees46ML::ChildAge.new if in_child?
        when "gender"
          self.current_element = Rees46ML::Gender.new
        when "ring_size"
          self.current_element = Rees46ML::RingSize.new if in_ring_sizes?
        when "bracelet_size"
          self.current_element = Rees46ML::BraceletSize.new if in_bracelet_sizes?
        when "chain_size"
          self.current_element = Rees46ML::ChainSize.new if in_chain_sizes?
        when "size"
          self.current_element = Rees46ML::Size.new
        when "skin"
          self.current_element = Rees46ML::Skin.new
        when "hair"
          self.current_element = Rees46ML::Hair.new
        when "nail"
          self.current_element = Rees46ML::Nail.new
        when "perfume"
          self.current_element = Rees46ML::Perfume.new
        when "auto"
          self.current_element = Rees46ML::Auto.new
        when "offer"
          self.current_element = Rees46ML::Offer.new
        when "param"
          self.current_element = Rees46ML::Param.new
        when "compatibility"
          self.current_element = Rees46ML::Compatibility.new if in_auto?
        end

        send event_name
        attrs.each{ |(k,v)| attr k,v }
      else
        start_unsupported_element name
      end
    end

    def end_element(name)
      debug "< #{ name }"

      if in_unsupported_element?
        self.current_element.text = safe_buffer

        if self.parent_element.present?
          self.parent_element.usupported_elements << self.current_element
        else
          @consumer.call self.current_element
        end

        stack.pop
      else

        if buffer?

          attibute = underscore(path.last)

          case attibute
          when "category_id"
            self.current_element.category_id << safe_buffer
          when 'seasonality'
            self.current_element.seasonality << safe_buffer
          when "barcode"
            self.current_element.barcodes << safe_buffer
          when "picture"
            self.current_element.pictures << safe_buffer
          when "vds"
            self.current_element.vds << safe_buffer
          when "part"
            if in_skin?
              self.current_element.part << safe_buffer
            else
              self.current_element.part = safe_buffer
            end
          when "type"
            self.current_element.type = safe_buffer if in_child?
            self.current_element.type = safe_buffer if in_fashion?
            self.current_element.type << safe_buffer if in_skin?
            self.current_element.type << safe_buffer if in_hair?
            self.current_element.type = safe_buffer if in_nail?
          when "condition"
            self.current_element.condition << safe_buffer if in_skin?
            self.current_element.condition << safe_buffer if in_hair?
            self.current_element.condition = safe_buffer if in_nail?
          when "data_tour"
            self.current_element.data_tours << safe_buffer
          # Вот так инициализируются значения, если на значение у нас собственный класс. Типа размеров.
          when 'ring_size'
            self.current_element.value = safe_buffer
          when 'bracelet_size'
            self.current_element.value = safe_buffer
          when 'chain_size'
            self.current_element.value = safe_buffer
          when 'aroma'
            self.current_element.aroma << safe_buffer
          when "currencies"
          else
            if self.current_element.respond_to?(attibute)
              (self.current_element[attibute] = safe_buffer)
            end
          end
        end

        case name
        when "category"
          self.parent_element.categories << self.current_element
          stack.pop
        when "location"
          self.parent_element.locations << self.current_element
          stack.pop
        when "accessory"
          self.parent_element.accessories << self.current_element
          stack.pop
        when "price"
          if in_location?
            self.parent_element.prices << self.current_element
            stack.pop
          end
        when "currency"
          self.parent_element.currencies << self.current_element
          stack.pop
        when "option"
          self.parent_element.delivery_options << self.current_element
          stack.pop
        when "param"
          self.parent_element.params << self.current_element
          stack.pop
        when "child"
          self.parent_element.child = self.current_element
          stack.pop
        when "fashion"
          self.parent_element.fashion = self.current_element
          stack.pop
        when "fmcg"
          self.parent_element.fmcg = self.current_element
          stack.pop
        when "jewelry"
          self.parent_element.jewelry = self.current_element
          stack.pop
        when "pets"
          self.parent_element.pets = self.current_element
          stack.pop
        when "auto"
          self.parent_element.auto = self.current_element
          stack.pop
        when "compatibility"
          self.parent_element.compatibility << self.current_element if in_auto?
          stack.pop
        when "cosmetic"
          self.parent_element.cosmetic = self.current_element
          stack.pop
        when "skin"
          self.parent_element.skin = self.current_element
          stack.pop
        when "hair"
          self.parent_element.hair = self.current_element
          stack.pop
        when "nail"
          self.parent_element.nail = self.current_element
          stack.pop
        when "perfume"
          self.parent_element.perfume = self.current_element
          stack.pop
        when "age"
          self.parent_element.age = self.current_element   if self.parent_element.respond_to?(:age)
          self.parent_element.ages << self.current_element if self.parent_element.respond_to?(:ages)
          stack.pop
        when "gender"
          self.parent_element.gender = self.current_element
          stack.pop
        when "volume"
          if in_cosmetic? || in_fmcg?
            self.parent_element.volumes << self.current_element
            stack.pop
          end
        when "size"
          self.parent_element.sizes << self.current_element
          stack.pop
        when "ring_size"
          self.parent_element.ring_sizes << self.current_element
          stack.pop
        when "bracelet_size"
          self.parent_element.bracelet_sizes << self.current_element
          stack.pop
        when "chain_size"
          self.parent_element.chain_sizes << self.current_element
          stack.pop
        when "offer"
          @consumer.call self.current_element
          stack.pop
        end

        send underscore("end_#{ name }")
      end

      reset_buffer!
      path.pop
    end

    def attr(name, value)
      debug " #{ name } : #{ value }"

      if in_unsupported_element?
        self.current_element.attrs[name] = value
      else
        attibute = underscore(name)

        if current_element
          if current_element.respond_to? "#{ attibute }="
            self.current_element[attibute] = value
          end
        end
      end
    end

    def buffer
      @buffer ||= ""
    end

    def safe_buffer
      buffer.encode('UTF-8', {invalid: :replace, undef: :replace, replace: ''})
    end

    def reset_buffer!
      @buffer = nil
    end

    def buffer?
      !@buffer.to_s.empty?
    end

    def text(value)
      return if value.strip.empty?
      buffer << value
      debug " text : #{ value }"
      value
    end

    alias_method :cdata_block, :text
    alias_method :characters, :text

    def stack
      @stack ||= []
    end

    def path
      @path ||= []
    end

    def current_element
      stack[-1]
    end

    def parent_element
      stack[-2]
    end

    def current_element=(value)
      stack.push value
    end

    def start_unsupported_element(name)
      self.current_element = Rees46ML::UnsupportedElement.new(name: name)
    end

    def in_unsupported_element?
      self.current_element.is_a? Rees46ML::UnsupportedElement
    end

    def debug(message)
      @logger.debug (" " * path.size) << message
    end

    def underscore(string)
      @underscore_cache ||= {}
      @underscore_cache[string] ||= begin
        v = string.to_s
        v.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        v.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
        v.downcase!
        v.tr("-", "_")
      end
    end
  end
end
