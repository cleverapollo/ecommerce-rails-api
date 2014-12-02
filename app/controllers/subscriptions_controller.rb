##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  before_action :fetch_shop, only: :create
  before_action :fetch_user, only: :create

  def create
    @subscription = @shop.subscriptions.find_or_initialize_by(user_id: @user.id)
    @subscription.update!(subscription_params)
    render json: {}
  end

  def unsubscribe
    @subscription = Subscription.find_by!(unsubscribe_token: params[:unsubscribe_token])
    @subscription.deactivate!
    render text: 'Вы успешно отписаны от рассылок.'
  end

  def track
    begin
      if trigger_mail = TriggerMail.find_by(code: params[:trigger_mail_code])
        trigger_mail.open!
      end
    rescue StandardError => e
      raise e
    end

    data = open('app/assets/images/pixel.png').read
    send_data data, type: 'image/png', disposition: 'inline'
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
