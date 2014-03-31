class MahoutService
  BRB_ADDRESS = 'brb://localhost:5555'

  attr_reader :tunnel

  def initialize
    @tunnel = BrB::Tunnel.create(nil, BRB_ADDRESS)
  end

  def user_based(user_id, shop_id, item_id, options)
    preferences = MahoutPreferences.new(user_id, shop_id, item_id).fetch
    options.merge!(preferences: preferences)
    res = nil
    if tunnel_active? and preferences.any?
      res = tunnel.user_based_block(nil, options)
      EM.stop
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
    if tunnel_active? and preferences.any?
      res = tunnel.item_based_weight_block(user_id, options)
      EM.stop
    else
      puts "Tunnel inactive!"
      res = options[:weight].slice(0, options[:limit])
    end
    return res
  end

  private

  def tunnel_active?
    tunnel.active?
  end
end