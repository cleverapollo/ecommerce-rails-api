##
# Корзины и покупки. Используются в коллаборативке.
# Пишутся напрямую в CF
##
class MahoutAction

  class << self

    def relink_user(options = {})
      mahout_service = MahoutService.new
      mahout_service.open
      mahout_service.relink_user(options.fetch(:from).id, options.fetch(:to).id)
      mahout_service.close
    end

    # @param [User] master
    # @param [Integer] slave_id
    def relink_user_remnants(master, slave_id)
      mahout_service = MahoutService.new
      mahout_service.open
      mahout_service.relink_user(slave_id, master.id)
      mahout_service.close
    end
  end

end
