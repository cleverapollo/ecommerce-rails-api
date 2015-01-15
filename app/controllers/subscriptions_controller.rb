##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  before_action :fetch_shop, only: :create
  before_action :fetch_user, only: :create

  def create
    # Broken
    # begin
    #   @subscription = @shop.subscriptions.find_or_initialize_by(user_id: @user.id)
    #   @subscription.update!(subscription_params)
    # rescue ActiveRecord::RecordNotUnique
    #   retry
    # end
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
    @user = Session.find_by!(uniqid: params[:ssid]).user
  end
end
