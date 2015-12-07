class AddOrderDateIndex < ActiveRecord::Migration
  def change
    add_index "orders", ["shop_id",  "date"]
  end
end
