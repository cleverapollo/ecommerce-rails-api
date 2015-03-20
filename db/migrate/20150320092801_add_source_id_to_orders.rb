class AddSourceIdToOrders < ActiveRecord::Migration
  def change
    add_reference :orders, :source, polymorphic: true, index: true
  end
end
