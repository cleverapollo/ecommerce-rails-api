class YmlImporter
  include Sidekiq::Worker

  sidekiq_options retry: 2, queue: "long", failures: true

  def perform(shop_id)
    shop = Shop.find(shop_id)
    shop.update_columns(last_try_to_load_yml_at: DateTime.current)

    yml_shop = shop.yml.detect{ |element| element.is_a?(Rees46ML::Shop) }

    yml_shop.categories.valid? # and … ? add to report
    yml_shop.locations.valid?  # and … ? add to report

    shop.yml.select{ |element| element.is_a?(Rees46ML::Offer) }.each do |offer|
      category_ids = yml_shop.categories.path_to(offer.category_id)
      location_ids = offer.locations.flat_map{ |l| yml_shop.locations.path_to(l.id) }

      OfferUpdater.perform_async shop.id, YAML.dump(offer), category_ids, location_ids
    end
  end
end
