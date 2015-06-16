class MahoutService
  BRB_ADDRESS = 'brb://localhost:5555'

  attr_reader :tunnel

  def open
    unless Rails.env.test?
      begin
        Timeout::timeout(2) {
          @tunnel = BrB::Tunnel.create(nil, BRB_ADDRESS)
        }
      rescue Timeout::Error => e
        retry
      rescue RuntimeError => e1
        retry
      end
    end
  end

  def close
    unless Rails.env.test?
      EM.stop if EM.reactor_running?
    end
  end

  # @param user_id
  # @param shop_id
  # @param item_id Если указан, то вся история пользователя будет состоять только из этого текущего товара, а если нет – то используем в качестве истории всю историю покупок клиента
  # @param options
  def user_based(user_id, shop_id, item_id, options)
    unless Rails.env.test?
      preferences = MahoutPreferences.new(user_id, shop_id, item_id).fetch
      options.merge!(preferences: preferences)
      res = nil
      if preferences.any? && tunnel_active?
        res = tunnel.user_based_block(shop_id, options)
      elsif preferences.none?
        res = []
      else
        res = []
      end
      return res
    else
      []
    end
  end

  def item_based_weight(user_id, options)
    unless Rails.env.test?
      preferences = Action.where(user_id: user_id).order('id desc').limit(10).pluck(:item_id)
      options.merge!(preferences: preferences)
      res = nil
      if tunnel_active? && preferences.any?
        res = tunnel.item_based_block(user_id, options)
      else
        res = options[:weight].slice(0, options[:limit]).map{|item| {item:item, rating:0.0}}
      end
      return res
    else
      options[:weight].slice(0, options[:limit]).map{|item| {item:item, rating:0.0}}
    end
  end

  def set_preference(shop_id, user_id, item_id, rating)
    unless Rails.env.test?
      if tunnel_active? && rating.to_f>0.0
        tunnel.set_preference_block(shop_id, {user_id:user_id, item_id:item_id, rating:rating})
      end
    end
  end



  def tunnel_active?
    unless Rails.env.test?
      if tunnel && tunnel.active?
        return true
      else
        open
        return tunnel && tunnel.active?
      end
     else
       false
     end
  end
end
