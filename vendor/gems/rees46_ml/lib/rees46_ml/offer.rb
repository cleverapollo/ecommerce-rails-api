module Rees46ML
  class Offer < Rees46ML::Element
    TYPES = %w[vendor.model book audiobook artist.title tour ticket event-ticket]

    attribute :id, Rees46ML::SafeString
    attribute :name, Rees46ML::SafeString
    attribute :type, Rees46ML::SafeString
    attribute :group_id, Rees46ML::SafeString
    attribute :market_category, Rees46ML::SafeString
    attribute :bid, Rees46ML::SafeString
    attribute :cbid, Rees46ML::SafeString
    attribute :available, Rees46ML::SafeString
    attribute :url, Rees46ML::URL
    attribute :price, Rees46ML::SafeString
    attribute :baseprice, Rees46ML::SafeString # ozon.ru only?
    attribute :oldprice, Rees46ML::SafeString
    attribute :currency_id, Rees46ML::SafeString
    attribute :category_id, Rees46ML::SafeString
    attribute :locations, Array
    attribute :accessories, Array
    attribute :ignored, Rees46ML::Boolean, default: false
    attribute :market_category, Rees46ML::SafeString
    attribute :pictures, Set[Rees46ML::URL]
    attribute :store, Rees46ML::Boolean
    attribute :pickup, Rees46ML::Boolean
    attribute :delivery, Rees46ML::Boolean
    attribute :adult, Rees46ML::Boolean
    attribute :ordering_time, Rees46ML::SafeString
    attribute :local_delivery_cost, Rees46ML::SafeString
    attribute :delivery_options, Set[Rees46ML::DeliveryOption]
    attribute :vendor, Rees46ML::SafeString
    attribute :sales_notes, Rees46ML::SafeString
    attribute :vendor_code, Rees46ML::SafeString
    attribute :description, Rees46ML::SafeString
    attribute :sales_notes, Rees46ML::SafeString
    attribute :manufacturer_warranty, Rees46ML::Boolean
    attribute :country_of_origin, Rees46ML::SafeString # https://yandex.st/market-export/97.0516af5f/partner/help/Countries.pdf
    attribute :ages, Set[Rees46ML::Age]
    attribute :barcodes, Set[Rees46ML::SafeString]
    attribute :cpa, Rees46ML::SafeString
    attribute :weight, Rees46ML::SafeString
    attribute :price_margin, Rees46ML::SafeString
    attribute :params, Set[Rees46ML::Param]
    attribute :type_prefix, Rees46ML::SafeString
    attribute :model, Rees46ML::SafeString
    attribute :author, Rees46ML::SafeString
    attribute :publisher, Rees46ML::SafeString
    attribute :series, Rees46ML::SafeString
    attribute :year, Rees46ML::SafeString
    attribute :isbn, Rees46ML::SafeString
    attribute :volume, Rees46ML::SafeString
    attribute :part, Rees46ML::SafeString
    attribute :language, Rees46ML::SafeString
    attribute :binding, Rees46ML::SafeString
    attribute :page_extent, Rees46ML::SafeString
    attribute :downloadable, Rees46ML::SafeString
    attribute :performed_by, Rees46ML::SafeString
    attribute :performance_type, Rees46ML::SafeString
    attribute :storage, Rees46ML::SafeString
    attribute :format, Rees46ML::SafeString
    attribute :recording_length, Rees46ML::SafeString
    attribute :artist, Rees46ML::SafeString
    attribute :title, Rees46ML::SafeString
    attribute :media, Rees46ML::SafeString
    attribute :starring, Rees46ML::SafeString
    attribute :director, Rees46ML::SafeString
    attribute :original_name, Rees46ML::SafeString
    attribute :country, Rees46ML::SafeString
    attribute :world_region, Rees46ML::SafeString
    attribute :region, Rees46ML::SafeString
    attribute :days, Rees46ML::SafeString
    attribute :data_tour, Rees46ML::SafeString
    attribute :hotel_stars, Rees46ML::SafeString
    attribute :room, Rees46ML::SafeString
    attribute :meal, Rees46ML::SafeString
    attribute :included, Rees46ML::SafeString
    attribute :transport, Rees46ML::SafeString
    attribute :place, Rees46ML::SafeString
    attribute :plan, Rees46ML::SafeString
    attribute :hall, Rees46ML::SafeString
    attribute :hall_part, Rees46ML::SafeString
    attribute :date, Rees46ML::SafeString
    attribute :is_premiere, Rees46ML::SafeString
    attribute :is_kids, Rees46ML::SafeString
    attribute :child, Rees46ML::Child
    attribute :fashion, Rees46ML::Fashion
    attribute :cosmetic, Rees46ML::Cosmetic

    alias_method :ordering, :ordering_time
    alias_method :ordering=, :ordering_time=

    validates :id, presence: true

    def gender
      return fashion.gender if fashion?
      return child.gender if child?
      return cosmetic.gender if cosmetic?
    end

    def type
      return fashion.type if fashion?
      return child.type if child?
    end

    def adult?
      !child? || adult
    end

    def child?
      child.present?
    end

    def fashion?
      fashion.present?
    end

    def cosmetic?
      cosmetic.present?
    end

    def part_types
      cosmetic.part_types
      child.part_types
    end

    def skin_types
      return cosmetic.skin_types if cosmetic?
      return child.skin_types if child?
    end

    def conditions
      return cosmetic.conditions if cosmetic?
      return child.conditions if child?
    end

    def with_usupported_elements?
      super ||
      (cosmetic && cosmetic.with_usupported_elements?) ||
      (child && child.with_usupported_elements?) ||
      (fashion && fashion.with_usupported_elements?) ||
      (delivery_options.any? && delivery_options.any?(&:with_usupported_elements?)) ||
      (ages.any? && ages.any?(&:with_usupported_elements?)) ||
      (params.any? && params.any?(&:with_usupported_elements?))
    end
  end
end
