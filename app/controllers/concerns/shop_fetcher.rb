module ShopFetcher
  def fetch_active_shop
    @shop = Shop.find_by(uniqid: params[:shop_id])

    if @shop.blank? || @shop.deactivated?
      render(nothing: true, status: 400) and return false
    end
  end
end
