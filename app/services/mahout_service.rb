class MahoutService
  BRB_ADDRESS = 'brb://localhost:5555'

  attr_reader :tunnel

  def open
    begin
      Timeout::timeout(2) {
        @tunnel = BrB::Tunnel.create(nil, BRB_ADDRESS)
      }
    rescue Timeout::Error => e
      retry
    end
  end

  def close
    EM.stop if EM.reactor_running?
  end

  def user_based(user_id, shop_id, item_id, options)
    preferences = MahoutPreferences.new(user_id, shop_id, item_id).fetch
    options.merge!(preferences: preferences)
    res = nil
    if preferences.any? && tunnel_active?
      res = tunnel.user_based_block(nil, options)
    elsif preferences.none?
      puts 'No preferences'
      res = []
    else
      puts "Tunnel inactive!"
      res = []
    end
    return res
  end

  def item_based_weight(user_id, options)
    preferences = Action.where(user_id: user_id).order('id desc').limit(10).pluck(:item_id)
    options.merge!(preferences: preferences)
    res = nil
    if tunnel_active? && preferences.any?
      res = tunnel.item_based_weight_block(user_id, options)
    else
      puts "Tunnel inactive!"
      res = options[:weight].slice(0, options[:limit])
    end
    return res
  end

  private

  def tunnel_active?
    if tunnel && tunnel.active?
      return true
    else
      open
      return tunnel && tunnel.active?
    end
  end
end