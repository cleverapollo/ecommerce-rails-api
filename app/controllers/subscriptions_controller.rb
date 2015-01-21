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
    if entity = ShopsUser.find_by(code: params[:code])
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

  def bounce
    if params[:type] == 'digest'
      if digest_mail = DigestMail.find_by(code: params[:code])
        digest_mail.mark_as_bounced!

        if digest_mail.shops_user.present? && digest_mail.shops_user.email.present?
          ShopsUser.where(email: digest_mail.shops_user.email).update_all(email: nil)
        end
      end
    end
  end

  protected

  def fetch_shop
    @shop = Shop.find_by!(uniqid: params[:shop_id])
  end

  def fetch_user
    @user = Session.find_by!(code: params[:ssid]).user
  end
end
