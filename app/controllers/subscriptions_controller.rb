##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  before_action :fetch_shop, only: :create
  before_action :fetch_user, only: :create

  def create
    begin
      @subscription = @shop.subscriptions.find_or_initialize_by(user_id: @user.id)
      @subscription.update!(subscription_params)
    rescue ActiveRecord::RecordNotUnique
      retry
    end
    render json: {}
  end

  def unsubscribe
    if params[:code] != 'test'
      entity = if params[:type] == 'trigger'
        Subscription.find_by!(code: params[:code])
      elsif params[:type] == 'digest'
        Audience.find_by!(code: params[:code])
      end

      entity.deactivate! if entity
    end

    render text: 'Вы успешно отписаны от рассылок.'
  end

  def track
    if params[:code] != 'test'
      entity = if params[:type] == 'trigger'
        TriggerMail.find_by(code: params[:code])
      elsif params[:type] == 'digest'
        DigestMail.find_by(code: params[:code])
      end

      entity.mark_as_opened! if entity
    end

    data = open("#{Rails.root}/app/assets/images/pixel.png").read
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
