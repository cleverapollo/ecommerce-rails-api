##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  include ShopFetcher
  before_action :fetch_shop, only: :create
  before_action :fetch_user, only: :create

  # Взаимодействие с окном сбора email
  def create
    client = shop.clients.find_or_create_by!(user_id: @user.id)

    if email = IncomingDataTranslator.email(params[:email])
      client.email = email
    end

    # Если params[:declined] == true, значит пользователь отказался
    client.accepted_subscription = (params[:declined] != true && params[:declined] != 'true')
    client.subscription_popup_showed = true
    client.save

    render json: {}
  end

  # Отписка от рассылок в один клик
  def unsubscribe
    if client = Client.find_by(code: params[:code])
      client.unsubscribe_from(params[:type])
    end

    render text: 'Вы успешно отписаны от рассылок.'
  end

  # Трекинг открытого письма
  def track
    if params[:code] != 'test'
      entity = Mail(params[:type]).find_by(code: params[:code])
      entity.mark_as_opened! if entity.present?
    end

    data = open("#{Rails.root}/app/assets/images/pixel.png").read
    send_data data, type: 'image/png', disposition: 'inline'
  end

  protected

  def fetch_user
    @user = Session.find_by!(code: params[:ssid]).user
  end
end
