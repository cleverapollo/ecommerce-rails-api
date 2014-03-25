class ImportsController < ApplicationController
  before_filter :fetch_shop
  before_filter :authenticate_shop

  def orders
    OrdersImportWorker.perform_async(@shop.id, params[:orders])
    render text: 'OK'
  end

  protected

    def fetch_shop
      @shop = Shop.find_by(uniqid: params[:shop_id], secret: params[:shop_secret])
    end

    def authenticate_shop
      if @shop.blank?
        render(text: 'Shop not found') and return false
      end
    end
end
