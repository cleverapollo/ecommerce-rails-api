class WebPush::BaseController < ActionController::Base
  before_action :fetch_settings

  def index
    response.headers.delete 'X-Frame-Options'
  end

  # Манифест файл для подписок
  def manifest
    render json: {
        name: @settings.shop.name,
        gcm_sender_id: '605730184710',
        display: 'standalone',
        start_url: '/',
    }
  end

  private

  def fetch_settings
    @settings = WebPushSubscriptionsSettings.find_by(subdomain: request.subdomain(2))
    if @settings.nil?
      render nothing: true, status: 404
      return
    end

    # Проверяем, подключен ли магазин
    if @settings.shop.nil? || !@settings.shop.connected?
      render nothing: true, status: 402
    end
  end
end