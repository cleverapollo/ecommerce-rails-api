##
# Контроллер, обрабатывающий подписки пользователей на рассылки
#
class SubscriptionsController < ApplicationController
  before_action :fetch_shop, only: :create
  before_action :fetch_user, only: :create

  def create
    client = @shop.clients.find_or_create_by!(user_id: @user.id)

    if email = IncomingDataTranslator.email(params[:email])
      client.email = email
    end

    client.accepted_subscription = (params[:declined] != true && params[:declined] != 'true')
    client.subscription_popup_showed = true
    client.save

    render json: {}
  end

  def unsubscribe
    if entity = Client.find_by(code: params[:code])
      if params[:type] == 'digest'
        entity.unsubscribe_from_digests!
      elsif params[:type] == 'trigger'
        entity.unsubscribe_from_triggers!
      end
    end

    render text: 'Вы успешно отписаны от рассылок.'
  end

  def track
    if params[:code] != 'test'
      entity = if params[:type] == 'digest'
        DigestMail.find_by(code: params[:code])
      elsif params[:type] = 'trigger'
        TriggerMail.find_by(code: params[:code])
      end

      entity.mark_as_opened! if entity.present?
    end

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
