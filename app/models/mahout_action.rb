##
# Корзины и покупки. Используются в коллаборативке
#
class MahoutAction < ActiveRecord::Base

  establish_connection MASTER_DB


  before_create :assign_timestamp

  belongs_to :item
  belongs_to :shop
  belongs_to :user

  class << self
    # @noff: закомментировал в качестве проверки тормозов
    # def relink_user(options = {})
    #   mahout_service = MahoutService.new
    #   mahout_service.open
    #   mahout_service.relink_user(options.fetch(:from).id, options.fetch(:to).id)
    #   mahout_service.close
    # end
  end

  protected

  def assign_timestamp
    self.timestamp = Time.current.to_i
  end
end
