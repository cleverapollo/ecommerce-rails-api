class MahoutService
  BRB_ADDRESS = 'localhost:5555'

  include ::NewRelic::Agent::MethodTracer

  attr_reader :tunnel

  def initialize(brb_adress = nil)
    @brb_address = brb_adress
    @brb_address = BRB_ADDRESS if brb_adress.nil? || brb_adress.empty?
    @brb_address = 'brb://'+@brb_address
  end

  def open
    unless Rails.env.test?
      begin
        Timeout::timeout(0.2) {
          @tunnel = BrB::Tunnel.create(nil, @brb_address)
        }
      rescue Timeout::Error => e
        return false
      rescue RuntimeError => e1
        return false
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

  def item_based_weight(user_id, shop_id, options)
    unless Rails.env.test?
      preferences = Action.where(user_id: user_id).order('id desc').limit(10).pluck(:item_id)
      options.merge!(preferences: preferences)
      res = nil
      if tunnel_active? && preferences.any?
        res = tunnel.item_based_block(shop_id, options)
      else
        res = options[:weight].slice(0, options[:limit]).map{|item| {item:item, rating:0.0}}
      end
      return res
    else
      options[:weight].slice(0, options[:limit]).map{|item| {item:item, rating:0.0}}
    end
  end

  add_method_tracer :user_based, 'Custom/user_based'
  add_method_tracer :item_based_weight, 'Custom/item_based_weight'

  def set_preference(shop_id, user_id, item_id, rating)
    unless Rails.env.test?
      if tunnel_active? && rating.to_f>0.0
        tunnel.set_preference(shop_id, {user_id:user_id, item_id:item_id, rating:rating})
      end
    end
  end



  def tunnel_active?
    unless Rails.env.test?
      if tunnel && tunnel.active?
        return true
      else
        if open
          return tunnel && tunnel.active?
        else
          false
        end
      end
     else
       false
     end
  end
end
