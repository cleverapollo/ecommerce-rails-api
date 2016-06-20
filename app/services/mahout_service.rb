class MahoutService
  BRB_ADDRESS = 'localhost:5555'
  SOCKET_PATH = Rails.env.production? ? '/home/rails/rees46_recommendations/socket_file.sock' : Rails.root.to_s + '/tmp/socket/socket_file.sock'

  attr_reader :socket

  def initialize(brb_adress = nil)
    unless Pathname.new(SOCKET_PATH).exist?
      dirname = File.dirname(SOCKET_PATH)
      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end
      File.new(SOCKET_PATH, "w").chmod(0666)
    end
  end

  def open
    unless Rails.env.test?
      begin
        Timeout::timeout(0.2) {
          @socket = UNIXSocket.new(SOCKET_PATH)
        }
      rescue Timeout::Error => e
        return false
      rescue RuntimeError => e1
        return false
      rescue Errno::ECONNREFUSED => e2
        return false
      end
    end
  end

  def close
    unless Rails.env.test?
      # EM.stop if EM.reactor_running?
      socket.close if socket.present? && !socket.closed?
    end
  end

  # @param user_id
  # @param shop_id
  # @param item_id Если указан, будет добавлен в историю товаров
  # @param options

  def user_based(user_id, shop_id, item_id, options)
    unless Rails.env.test?
      preferences = MahoutPreferences.new(user_id, shop_id, item_id).fetch
      options.merge!(preferences: preferences)
      res = nil
      if preferences.any? && socket_active?
        query = options
        query.merge!(function: 'user_based', shop_id: shop_id, user_id: user_id)

        res = []

        begin
          socket.puts(query.to_json)
          Timeout::timeout(0.3) {
            res = socket.gets
          }
          close
        rescue Timeout::Error
          close
          return []
        rescue
          return []
        end

        res = JSON.parse(res).values if res.present?
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
      if socket_active? && preferences.any?
        query = options
        query.merge!(function: 'item_based', shop_id: shop_id)
        begin

          socket.puts(query.to_json)
          Timeout::timeout(0.3) {
            res = socket.gets
          }
          close

        rescue Timeout::Error
          close
          return options[:weight].slice(0, options[:limit]).map{|item| {item:item, rating:0.0}}
        rescue
          return options[:weight].slice(0, options[:limit]).map{|item| {item:item, rating:0.0}}
        end
        res = if JSON.parse(res).values[0].present?
            JSON.parse(res).values[0].sort.to_h.first(options[:limit]).map { |i| { item: i[0].to_i, rating: i[1] } }
          else
            res = []
          end
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
      if socket_active? && rating.to_f>0.0
        begin
          socket.puts({
              function: 'set_preference',
              shop_id: shop_id,
              user_id: user_id,
              item_id: item_id,
              rating: rating
            }.to_json)
          close
        rescue Errno::EPIPE => e
          return false
        rescue error
          Rollbar.error(error)
          return false
        end
      end
    end
  end

  def relink_user(from, to, use_socket = true)
    unless Rails.env.test?
      if use_socket && socket_active?
        begin
          socket.puts({ function: 'relink_user', from: from, to: to }.to_json)
          close
        rescue Errno::EPIPE => e
          return false
        rescue error
          Rollbar.error(error)
          return false
        end
      end
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
