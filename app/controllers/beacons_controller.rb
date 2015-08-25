class BeaconsController < ApplicationController
  def notify
    if shop = Shop.find_by(uniqid: params[:shop_id])

      session = Session.find_by(code: params[:ssid])
      if session.blank?
        return respond_with_client_error('Session not found')
      end

      user = session.user

      beacon_offer = BeaconOffer.active.where(shop_id: shop.id, uuid: params[:uuid], major: params[:major]).limit(1)[0]
      if beacon_offer.nil?
        return respond_with_client_error('Beacon Offer not found')
      end

      beacon_message = shop.beacon_messages.new
      beacon_message.user = user
      beacon_message.beacon_offer_id = beacon_offer.id
      beacon_message.session = session
      beacon_message.params = params
      beacon_message.save!

      if params[:type] == 'lead' &&
        shop.beacon_messages.where(user_id: user.id).with_notifications.where('created_at >= ?', 2.weeks.ago).none?
        beacon_message.update(notified: true, beacon_offer_id: beacon_offer.id)
        result = {
          image: beacon_offer.image_url,
          title: beacon_offer.title,
          notification: beacon_offer.notification,
          description: beacon_offer.description,
          deal_id: beacon_offer.id
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

      beacon_offer = BeaconOffer.active.where(shop_id: shop.id, uuid: params[:uuid], major: params[:major]).limit(1)[0]
      if beacon_offer.nil?
        return respond_with_client_error('Beacon Offer not found')
      end

      if b_m = shop.beacon_messages.where(user_id: user.id, beacon_offer_id: beacon_offer.id).last
        b_m.update_columns(tracked: true)
      end
    else
      respond_with_client_error('Shop not found')
    end

    render nothing: true, status: 204
  end
end
