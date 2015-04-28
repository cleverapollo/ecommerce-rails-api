##
# Позволяет получать магазин различными методами
#
module ShopFetcher
  attr_reader :shop

  def fetch_active_shop
    @shop = Shop.find_by(uniqid: params[:shop_id])

    if @shop.blank? || @shop.deactivated?
      render(nothing: true, status: 400) and return false
    end
  end

  def fetch_non_restricted_shop
    @shop = Shop.find_by(uniqid: params[:shop_id])
    if @shop.blank? || @shop.restricted?
      render(json: []) and return false
    end
  end

  def fetch_shop
    @shop = Shop.find_by(uniqid: params[:shop_id])
    if @shop.blank?
      render(nothing: true) and return false
    end
  end
end
