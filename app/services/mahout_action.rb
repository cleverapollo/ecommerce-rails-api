##
# Корзины и покупки. Используются в коллаборативке
#
class MahoutAction

  class << self
    def relink_user(options = {})
      mahout_service = MahoutService.new
      mahout_service.open
      mahout_service.relink_user(options.fetch(:from).id, options.fetch(:to).id)
      mahout_service.close
    end
  end

end
