class YmlImporter
  include Sidekiq::Worker

  sidekiq_options retry: false, queue: "long"

  def perform(shop_id)
    shop = Shop.find(shop_id)
    shop.update_columns(last_try_to_load_yml_at: DateTime.current)

    shop.yml_file do |yml|
      shop.update_columns(yml_loaded: true, last_valid_yml_file_loaded_at: Time.current, yml_errors: 0)

      yml_shop = yml.lazy.detect{ |element| element.is_a?(Rees46ML::Shop) }

      yml_shop.categories.valid? # and … ? add to report
      yml_shop.locations.valid?  # and … ? add to report

      yml.lazy.select{ |element| element.is_a?(Rees46ML::Offer) }.each_with_index do |offer, index|
        category_ids = yml_shop.categories.path_to(offer.category_id)
        location_ids = offer.locations.flat_map{ |l| yml_shop.locations.path_to(l.id) }

        # OfferUpdater.perform_async shop.id, YAML.dump(offer), category_ids, location_ids
        OfferUpdater.new.perform shop.id, YAML.dump(offer), category_ids, location_ids
      end
    end
  end
end
