class ProductsController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop

  # Получить информацию о товаре
  def get
    if item = shop.items.available.widgetable.find_by(uniqid: params[:item_id])
      render json: {
          name: item.name,
          description: item.description,
          price: item.price,
          currency: shop.currency,
          url: item.url,
          picture: item.image_url
      }
    else
      render json: nil
    end
  end

  def set_not_widgetable
    item = shop.find_by_id(params[:item_id])
    item.update(widgetable: false) if item

    render nothing: true, status: :ok
  end



end
