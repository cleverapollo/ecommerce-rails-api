##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  before_action :fetch_shop, only: :create
  before_action :fetch_user, only: :create

  def create
    shops_user = @shop.shops_users.find_or_create_by!(user_id: @user.id)

    if email = IncomingDataTranslator.email(params[:email])
      shops_user.email = email
    end

    shops_user.accepted_subscription = (params[:declined] != true && params[:declined] != 'true')
    shops_user.subscription_popup_showed = true
    shops_user.save

    render json: {}
  end

  def unsubscribe
    # Broken

    render text: 'Вы успешно отписаны от рассылок.'
  end

  def track
    # Broken

    data = open("#{Rails.root}/app/assets/images/pixel.png").read
    send_data data, type: 'image/png', disposition: 'inline'
  end

  protected

  def fetch_shop
    @shop = Shop.find_by!(uniqid: params[:shop_id])
  end

  def fetch_user
    @user = Session.find_by!(code: params[:ssid]).user
  end
end
