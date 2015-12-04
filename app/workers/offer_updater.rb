class OfferUpdater
  include Sidekiq::Worker

  sidekiq_options retry: 2

  def perform(shop_id, offer_dump, category_ids, location_ids)
    offer = YAML.load(offer_dump)

    Item.where(shop_id: shop_id, uniqid: offer.id).first_or_initialize { |item|
      item.name = offer.name
      item.description = offer.description
      item.model = offer.model
      item.price = offer.price
      item.url = offer.url
      item.image_url = offer.pictures.first
      item.type_prefix = offer.type_prefix
      item.vendor_code = offer.vendor_code
      item.gender = offer.gender.value if offer.gender
      item.barcode = offer.barcodes.first

      item.category_ids = category_ids
      item.location_ids = location_ids.uniq

      if offer.fashion?
        item.feature = offer.fashion.feature
        item.wear_type = offer.type
        item.brand = offer.fashion.brand

        size_table = "SizeTables::#{ offer.type.camelcase }".constantize.new
        item.sizes = offer.fashion.sizes.map { |size|
          size_table.value(offer.gender.value, size.region, (offer.adult? ? :adult : :child), size.value)
        }.compact
      elsif offer.child?
        item.hypoallergenic = offer.child.hypoallergenic
        item.periodic = offer.child.periodic
        item.age_min = offer.child.age.min
        item.age_max = offer.child.age.max
      elsif offer.cosmetic?
        item.hypoallergenic = offer.cosmetic.hypoallergenic
        item.periodic = offer.cosmetic.periodic
      end

      item.part_type = offer.part_types.map(&:value) if offer.part_types
      item.skin_type = offer.skin_types.map(&:value) if offer.skin_types
      item.condition = offer.conditions.map(&:value) if offer.conditions

      # TODO : item.volume = offer.volume

      item.is_available = !!offer.available
      item.ignored = !!offer.ignored
      item.widgetable = item.name.present? &&
                        item.url.present? &&
                        item.image_url.present? &&
                        item.price.present?
    }.save!
  end
end
