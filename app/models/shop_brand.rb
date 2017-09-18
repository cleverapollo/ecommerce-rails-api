class ShopBrand < ActiveRecord::Base
  validates :shop_id, :brand, :popularity, presence: true

  class << self

    # Update shops statistics about brands usage
    # @param shop_id [Integer] Shop ID
    # @param brands_list [Array] List of brands in format [ ['brand_1', 33], ['brand_2', 13] ]
    # @return nil
    def bulk_update(shop_id, brands_list)
      return if brands_list.empty?
      transaction do
        ShopBrand.where(shop_id: shop_id).delete_all
        brands_list.each do |element|
          ShopBrand.create shop_id: shop_id, popularity: element[1], brand: element[0]
        end
      end
      nil
    end

  end

end
