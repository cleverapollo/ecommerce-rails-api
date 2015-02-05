class BeaconsController < ApplicationController
  def notify
    if shop = Shop.find_by(uniqid: params[:shop_id])
      session = Session.find_by(code: params[:ssid])

      if session.blank?
        return respond_with_client_error('Session not found')
      end

      user = session.user

      beacon_message = shop.beacon_messages.new
      beacon_message.user = user
      beacon_message.session = session
      beacon_message.params = params
      beacon_message.save!

      if params[:type] == 'lead' &&
        shop.beacon_messages.where(user_id: user.id).with_notifications.where('created_at >= ?', 2.weeks.ago).none?
        deal_id = '1'
        beacon_message.update(notified: true, deal_id: deal_id)
        result = {
          image: 'http://cdn.rees46.com/bk.png',
          title: 'Обед Кинг Хит – всего за 149 рублей',
          description: "Привет!\nАкция от БургерКинг - покажи на кассе этот экран и получи обед Кинг Хит всего за 149 рублей.",
          deal_id: deal_id
        }
        render json: result
      else
        render nothing: true, status: 204
      end
    else
      respond_with_client_error('Shop not found')
    end
  end

  def track
    if shop = Shop.find_by(uniqid: params[:shop_id])
      session = Session.find_by(code: params[:ssid])

      if session.blank?
        return respond_with_client_error('Session not found')
      end

      user = session.user

      deal_id = params[:deal_id].to_s
      if b_m = shop.beacon_messages.where(user_id: user.id, deal_id: deal_id).last
        b_m.update_columns(tracked: true)
      end
    else
      respond_with_client_error('Shop not found')
    end

    render nothing: true, status: 204
  end
end
