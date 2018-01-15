module Rees46ML
  class Perfume < Rees46ML::Element

    AROMA_TYPES = %w(floral fruity_floral soft_floral floral_oriental soft_oriental oriental woody_oriental woods mossy_woods dry_woods aromatic citrus water green fruity)
    FAMILY_TYPES = %w(floral oriental woody fresh)

    attribute :family, String, lazy: true
    attribute :aroma, String, lazy: true

  end
end
