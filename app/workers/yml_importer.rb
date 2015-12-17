require "csv"

class YmlImporter
  include Sidekiq::Worker
  include TempFiles

  sidekiq_options retry: 2, queue: "long", failures: true, backtrace: true

  def perform(shop_id)
    Shop.find(shop_id).import do |yml, report|
      shop = yml.shop

      if !shop.present?
        report.shop_not_exists!
      else
        report.invalid_locations! shop.locations
        report.invalid_categories! shop.categories
        
        wear_types = WearTypeDictionary.index
        brands = Brand.all

        offers_count = 0

        temp_file do |file|
          csv_file file, col_sep: "," do |csv|
            csv << Item.csv_header

            yml.offers.each_with_index do |offer, index|
              next unless offer.id.present?
              category_ids = shop.categories.path_to offer.category_id
              category = shop.categories[offer.category_id].try(:name)
              location_ids = offer.locations.flat_map{ |location| shop.locations.path_to location.id }

              offers_count += 1

              report.invalid_offer! offer unless offer.valid?

              new_item = Item.build_by_offer(offer)
              new_item.id = index
              new_item.shop_id = shop_id
              new_item.category_ids = category_ids
              new_item.location_ids = location_ids.uniq
              new_item.locations = {}
              new_item.categories = category_ids
              (new_item.wear_type ||= wear_types.detect { |(size_type, regexp)| regexp.match(new_item.name) }.try(:first)) if new_item.name.present?
              (new_item.wear_type ||= wear_types.detect { |(size_type, regexp)| regexp.match(category) }.try(:first)) if category.present?
              (new_item.brand ||= brands.detect{ |brand| brand.match? new_item.name }.try(:name)) if new_item.name.present?

              csv << new_item.csv_row
            end
          end

          attempt = 0

          begin
            Item.bulk_update shop_id, file
            ItemCategory.bulk_update shop_id, shop.categories
          rescue PG::UniqueViolation
            attempt += 1
            retry if attempt < 10
          end
        end

        if offers_count == 0
          report.offers_not_exists!
        elsif offers_count <= 5
          report.offers_less_than_five!
        end
      end
    end
  end
end
