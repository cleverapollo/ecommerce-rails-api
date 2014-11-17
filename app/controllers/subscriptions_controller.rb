##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  before_action :fetch_shop
  before_action :fetch_user

  def create
    @subscription = @shop.subscriptions.find_or_initialize_by(user_id: @user.id)
    @subscription.update!(subscription_params)
    render json: {}
  end

  protected

  def subscription_params
    params.require(:subscription).permit(:name, :email, :declined)
  end

  def fetch_shop
    @shop = Shop.find_by!(uniqid: params[:shop_id])
  end

  def fetch_user
    @user = Session.find_by!(uniqid: params[:ssid]).user
  end
end
