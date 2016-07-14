require "csv"

class YmlImporter
  include Sidekiq::Worker
  include TempFiles

  sidekiq_options retry: 2, queue: "long", failures: true, backtrace: true

  # Точка входа обработки YML
  # @param shop_id [Integer]
  def perform(shop_id)

    Shop.find(shop_id).import do |yml|

      shop = yml.shop
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
            locations = {}
            offer.locations.each { |l| locations[l.id] = {}; locations[l.id]['price'] = l.prices.first.value.to_i if l.prices.any? } if offer.locations && offer.locations.any?

            offers_count += 1

            new_item = Item.build_by_offer(offer)
            new_item.id = index
            new_item.shop_id = shop_id
            new_item.category_ids = category_ids
            new_item.location_ids = location_ids.uniq
            new_item.locations = locations
            (new_item.fashion_wear_type ||= wear_types.detect { |(size_type, regexp)| regexp.match(new_item.name) }.try(:first)) if new_item.name.present?
            (new_item.fashion_wear_type ||= wear_types.detect { |(size_type, regexp)| regexp.match(category) }.try(:first)) if category.present?
            if new_item.name.present? && (new_item.brand.nil? || !new_item.brand.present?)
              new_item.brand = brands.detect{ |brand| brand.match? new_item.name }.try(:name)
            end
            new_item.brand_downcase = new_item.brand.downcase if new_item.brand.present? && new_item.brand_downcase.nil?

            csv << new_item.csv_row
          end
        end

        attempt = 0

        begin
          Item.bulk_update shop_id, file
          ItemCategory.bulk_update shop_id, shop.categories
        rescue PG::UniqueViolation => e
          Rollbar.warning(e, "YML bulk operations error, attempt #{attempt}")
          attempt += 1
          retry if attempt < 10
        end
      end
    end
  end
end
