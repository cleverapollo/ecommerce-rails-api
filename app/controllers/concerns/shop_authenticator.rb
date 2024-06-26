##
# Авторизует магазин по коду и секретному коду.
#
module ShopAuthenticator
  extend ActiveSupport::Concern

  included do
    before_action :fetch_and_authenticate_shop
  end

  protected

  def fetch_and_authenticate_shop
    @shop = Shop.find_by(uniqid: params[:shop_id], secret: params[:shop_secret])
    I18n.locale = @shop.customer.language if @shop.present?
    if @shop.blank?
      respond_with_client_error('Incorrect shop credentials') and return false
    end
    if @shop.deactivated?
      respond_with_client_error('Shop deactivated') and return false
    end
  end
end
