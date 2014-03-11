class MahoutService
  BRB_ADDRESS = 'brb://localhost:5555'

  attr_reader :tunnel

  def initialize
    @tunnel = BrB::Tunnel.create(nil, BRB_ADDRESS)
  end

  def user_based(user_id, options)
    if tunnel_active?
      tunnel.user_based_block(user_id, options)
    else
      return []
      puts "Tunnel inactive!"
    end
  end

  def item_based_weight(user_id, options)
    if tunnel_active?
      tunnel.item_based_weight_block(user_id, options)
    else
      puts "Tunnel inactive!"
      return options[:weight].slice(0, options[:limit])
    end
  end

  private

  def tunnel_active?
    tunnel.active?
  end
end