module Rees46ML
  class Offer < Rees46ML::Element
    TYPES = %w[vendor.model book audiobook artist.title tour ticket event-ticket]

    attribute :id, String, lazy: true
    attribute :name, String, default: "", lazy: true
    attribute :adult, Rees46ML::Boolean, lazy: true
    attribute :artist, String, default: "", lazy: true
    attribute :author, String, default: "", lazy: true
    attribute :available, Rees46ML::Boolean, lazy: true
    attribute :bid, Integer, lazy: true
    attribute :binding, String, default: "", lazy: true
    attribute :category_id, Set[String], lazy: true
    attribute :cbid, Integer, lazy: true
    attribute :country, String, default: "", lazy: true
    attribute :country_of_origin, String, default: "", lazy: true
    attribute :cpa, String, default: "", lazy: true
    attribute :currency_id, String, default: "", lazy: true
    attribute :data_tours, Set[String], lazy: true
    attribute :date, String, default: "", lazy: true
    attribute :days, String, default: "", lazy: true
    attribute :delivery, Rees46ML::Boolean, lazy: true
    attribute :description, String, default: "", lazy: true
    attribute :director, String, default: "", lazy: true
    attribute :downloadable, Rees46ML::Boolean, lazy: true
    attribute :format, String, default: "", lazy: true
    attribute :group_id, String, default: "", lazy: true
    attribute :hall, String, default: "", lazy: true
    attribute :hall_part, String, default: "", lazy: true
    attribute :hotel_stars, String, default: "", lazy: true
    attribute :ignored, Rees46ML::Boolean, default: false, lazy: true
    attribute :included, String, default: "", lazy: true
    attribute :is_kids, Rees46ML::Boolean, lazy: true
    attribute :is_premiere, Rees46ML::Boolean, lazy: true
    attribute :isbn, String, default: "", lazy: true
    attribute :language, String, default: "", lazy: true
    attribute :local_delivery_cost, String, default: "", lazy: true
    attribute :manufacturer_warranty, Rees46ML::Boolean, lazy: true
    attribute :market_category, String, default: "", lazy: true # http://download.cdn.yandex.net/market/market_categories.xls
    attribute :meal, String, default: "", lazy: true
    attribute :media, String, default: "", lazy: true
    attribute :model, String, default: "", lazy: true
    attribute :oldprice, String, default: "", lazy: true
    attribute :original_name, String, default: "", lazy: true
    attribute :page_extent, String, default: "", lazy: true
    attribute :params, Set[Rees46ML::Param], lazy: true
    attribute :part, String, default: "", lazy: true
    attribute :performance_type, String, default: "", lazy: true
    attribute :performed_by, String, default: "", lazy: true
    attribute :pickup, Rees46ML::Boolean, lazy: true
    attribute :place, String, default: "", lazy: true
    attribute :price, String, default: "", lazy: true
    attribute :price_margin, String, default: "", lazy: true
    attribute :publisher, String, default: "", lazy: true
    attribute :recording_length, String, default: "", lazy: true
    attribute :region, String, default: "", lazy: true
    attribute :room, String, default: "", lazy: true
    attribute :sales_notes, String, default: "", lazy: true
    attribute :series, String, default: "", lazy: true
    attribute :starring, String, default: "", lazy: true
    attribute :storage, String, default: "", lazy: true
    attribute :store, Rees46ML::Boolean, lazy: true
    attribute :title, String, default: "", lazy: true
    attribute :transport, String, default: "", lazy: true
    attribute :type, String, default: "", lazy: true
    attribute :type_prefix, String, default: "", lazy: true
    attribute :url, URL, default: "", lazy: true
    attribute :vendor, String, default: "", lazy: true
    attribute :vendor_code, String, default: "", lazy: true
    attribute :volume, String, default: "", lazy: true
    attribute :weight, String, default: "", lazy: true
    attribute :world_region, String, default: "", lazy: true
    attribute :year, String, default: "", lazy: true
    attribute :seasonality, Set[String], lazy: true

    attribute :delivery_options, Set[Rees46ML::DeliveryOption], lazy: true
    attribute :ages, Set[Rees46ML::Age], lazy: true
    attribute :barcodes, Set[String], lazy: true

    attribute :child, Rees46ML::Child, lazy: true
    attribute :fashion, Rees46ML::Fashion, lazy: true
    attribute :cosmetic, Rees46ML::Cosmetic, lazy: true
    attribute :fmcg, Rees46ML::Fmcg, lazy: true
    attribute :pets, Rees46ML::Pets, lazy: true
    attribute :auto, Rees46ML::Auto, lazy: true
    attribute :jewelry, Rees46ML::Jewelry, lazy: true
    attribute :pictures, Set[URL], lazy: true # Почему-то не срабатывает тут url.rb с очисткой левых символов

    attribute :locations, Set, lazy: true
    attribute :accessories, Set, lazy: true

    validates :id, presence: true

    validate do |offer|
      if cosmetic? && cosmetic.invalid?
        cosmetic.errors.full_messages.each do |msg|
          errors.add(:base, "Cosmetic Error: #{ msg }")
        end
      end

      if fmcg? && fmcg.invalid?
        fmcg.errors.full_messages.each do |msg|
          errors.add(:base, "FMCG Error: #{ msg }")
        end
      end

      if pets? && pets.invalid?
        pets.errors.full_messages.each do |msg|
          errors.add(:base, "Pets error: #{ msg }")
        end
      end

      if auto? && auto.invalid?
        auto.errors.full_messages.each do |msg|
          errors.add(:base, "Auto Error: #{ msg }")
        end
      end

      if fashion? && fashion.invalid?
        fashion.errors.full_messages.each do |msg|
          errors.add(:base, "Fashion Error: #{ msg }")
        end
      end

      if child? && child.invalid?
        child.errors.full_messages.each do |msg|
          errors.add(:base, "Child Error: #{ msg }")
        end
      end

      if jewelry? && jewelry.invalid?
        jewelry.errors.full_messages.each do |msg|
          errors.add(:base, "Jewelry Error: #{ msg }")
        end
      end

    end

    def adult?
      !child?
    end

    def child?
      child.present?
    end

    def fashion?
      fashion.present?
    end

    def jewelry?
      jewelry.present?
    end

    def cosmetic?
      cosmetic.present?
    end

    def fmcg?
      fmcg.present?
    end

    def pets?
      pets.present?
    end

    def auto?
      auto.present?
    end

    def to_xml
      Nokogiri::XML::Builder.new { |xml|
        xml.offer(id: self.id, available: self.available) {
          xml.url         { xml.text self.url }         if self.url
          xml.price       { xml.text self.price }       if self.price
          xml.price_margin { xml.text self.price_margin } if self.price_margin
          xml.categoryId  { xml.text self.category_id } if self.category_id
          xml.name        { xml.text self.name }        if self.name
          xml.description { xml.text self.description } if self.description
          xml.typePrefix  { xml.text self.type_prefix } if self.type_prefix
          xml.vendor      { xml.text self.vendor }      if self.vendor
          xml.vendorCode  { xml.text self.vendor_code } if self.vendor_code
          xml.model       { xml.text self.model }       if self.model

          self.pictures.each { |url| xml.picture! url }
          self.barcodes.each { |barcode| xml.barcode! barcode }
        }
      }.doc.root
    end
  end
end
