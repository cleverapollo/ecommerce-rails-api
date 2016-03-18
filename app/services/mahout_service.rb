class MahoutService
  BRB_ADDRESS = 'localhost:5555'
  SOCKET_PATH = Rails.env.development? ? '/home/maroki/IdeaProjects/rees46_recommender/socket_file.sock' : '/home/rails/rees46_recommendations/socket_file.sock'

  attr_reader :tunnel
  attr_reader :socket

  # DONE
  def initialize(brb_adress = nil)
    @brb_address = brb_adress
    @brb_address = BRB_ADDRESS if brb_adress.nil? || brb_adress.empty?
    @brb_address = 'brb://'+@brb_address
  end

  # DONE---------!!!!
  def open
    unless Rails.env.test?

      begin
        Timeout::timeout(0.2) {
          @socket = UNIXSocket.new(SOCKET_PATH)
          @tunnel = BrB::Tunnel.create(nil, @brb_address)
        }
      rescue Timeout::Error => e
        return false
      rescue RuntimeError => e1
        return false
      end
    end
  end

  # DONE---------!!!!
  def close
    unless Rails.env.test?
      EM.stop if EM.reactor_running?
      unless socket && socket.closed?
        @socket.close
      end
    end
  end

  # DONE---------!!!!

  # @param user_id
  # @param shop_id
  # @param item_id Если указан, будет добавлен в историю товаров
  # @param options
    # user_based(828828828828, 828, 98465432164654, include: [], exclude: [654654654654,654654651321321,13213213213], limit: 4)

  def user_based(user_id, shop_id, item_id, options)
    unless Rails.env.test?
      preferences = MahoutPreferences.new(user_id, shop_id, item_id).fetch
      options.merge!(preferences: preferences)
      res = nil
      if shop_id == 828
        if preferences.any? && socket_active?
          query = options
          query.merge!(function: 'user_based', shop_id: shop_id, user_id: user_id)
          socket.puts(query.to_json)

          res = []
          Timeout::timeout(2) {
            res = socket.gets
          }
          close
          res = JSON.parse(res).values
        elsif preferences.none?
          res = []
        else
          res = []
        end
      else
        if preferences.any? && tunnel_active?
          res = tunnel.user_based_block(shop_id, options)
        elsif preferences.none?
          res = []
        else
          res = []
        end
      end
      return res
    else
      []
    end
  end

  # DONE
  def item_based_weight(user_id, shop_id, options)
    unless Rails.env.test?
      preferences = Action.where(user_id: user_id).order('id desc').limit(10).pluck(:item_id)
      options.merge!(preferences: preferences)
      res = nil
      if shop_id == 828 && socket_active? && preferences.any?
        query = options
        query.merge!(function: 'item_based', shop_id: shop_id)
        socket.puts(query.to_json)
        Timeout::timeout(2) {
          res = socket.gets
        }
        close
        puts res
        res
      elsif tunnel_active? && preferences.any?
        res = tunnel.item_based_block(shop_id, options)
      else
        res = options[:weight].slice(0, options[:limit]).map{|item| {item:item, rating:0.0}}
      end
      return res
    else
      options[:weight].slice(0, options[:limit]).map{|item| {item:item, rating:0.0}}
    end
  end

  # DONE
  def set_preference(shop_id, user_id, item_id, rating)
    unless Rails.env.test?
      if shop_id == 828 && socket_active? && rating.to_f>0.0
        socket.puts({
            function: 'set_preference',
            shop_id: shop_id,
            user_id: user_id,
            item_id: item_id,
            rating: rating
          }.to_json)
        close
      elsif shop_id != 828 && tunnel_active? && rating.to_f>0.0
        tunnel.set_preference(shop_id, {user_id:user_id, item_id:item_id, rating:rating})
      end
    end
  end

  # TODO
  def relink_user(from, to, use_socket = false)
    unless Rails.env.test?
      if use_socket && socket_active?
        socket.puts({ function: 'relink_user', from: from, to: to }.to_json)
        close
      elsif tunnel_active? && !use_socket
        tunnel.relink_user({from:from, to:to})
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

  def socket_active?
    unless Rails.env.test?
      if socket && !socket.closed?
        return true
      else
        if open
          return socket && !socket.closed?
        else
          false
        end
      end
     else
       false
     end
  end
end
