class ShopsController < ApplicationController
  include ShopFetcher
  before_action :fetch_shop
  
  def update
    if @shop.update(shop_params)
      respond_with_success
    else
      respond_with_client_error(@shop.errors.full_messages.join(','))
    end
  end

  private

  def shop_params
    params.require(:shop).permit(:track_order_status)
  end

end
