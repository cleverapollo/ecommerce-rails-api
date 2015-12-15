require "csv"

class YmlImporter
  include Sidekiq::Worker
  include TempFiles

  sidekiq_options retry: 2, queue: "long", failures: true, backtrace: true

  def perform(shop_id)
    shop = Shop.find(shop_id)
    report = YmlReport.new
    report.shop_id = shop_id

    yml_file = shop.yml
    yml_shop = yml_file.shop

    if !yml_shop.present?
      report.shop_not_exists!
    # elsif yml_shop.categories.invalid?
    # elsif yml_shop.locations.invalid?
    else
      report.invalid_locations! yml_shop.locations
      report.invalid_categories! yml_shop.categories
      
      wear_type_dictionaries_index = WearTypeDictionary.index
      brand_index = Brand.all

      offers_count = 0

      temp_file do |file|
        csv_file file, col_sep: ',' do |csv|
          csv << Item.csv_header

          yml_file.offers.each_with_index do |offer, index|
            category_ids = yml_shop.categories.path_to offer.category_id
            category = yml_shop.categories[offer.category_id].try(:name)
            location_ids = offer.locations.flat_map{ |location| yml_shop.locations.path_to location.id }

            offers_count += 1

            report.invalid_offer! offer unless offer.valid?

            new_item = Item.build_by_offer(offer)
            new_item.id = index
            new_item.shop_id = shop_id
            new_item.category_ids = category_ids
            new_item.location_ids = location_ids.uniq
            new_item.locations = {}
            new_item.categories = category_ids
            (new_item.wear_type ||= wear_type_dictionaries_index.detect { |(size_type, regexp)| regexp.match(new_item.name) }.try(:first)) if new_item.name.present?
            (new_item.wear_type ||= wear_type_dictionaries_index.detect { |(size_type, regexp)| regexp.match(category) }.try(:first)) if category.present?
            (new_item.brand ||= brand_index.detect{ |brand| brand.match? new_item.name }.try(:name)) if new_item.name.present?

            csv << new_item.csv_row
          end
        end

        attempt = 0

        begin
          Item.bulk_update shop_id, file
          ItemCategory.bulk_update shop_id, yml_shop.categories
        rescue PG::UniqueViolation
          attempt += 1
          retry if attempt < 3
        end
      end

      if offers_count == 0
        report.offers_not_exists!
      elsif offers_count <= 5
        report.offers_less_than_five!
      end
    end

    # YMLMailer.report(YAML.dump(report)).deliver_now if report.errors.any?
  end
end
