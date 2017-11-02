##
# Товар в заказе
#
class OrderItem < ActiveRecord::Base

  belongs_to :order
  belongs_to :item
  belongs_to :action
  belongs_to :shop

  validates :shop_id, presence: true

end
