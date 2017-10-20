class ChangeOrderItemActionToNull < ActiveRecord::Migration
  def change
    change_column_null :order_items, :action_id, true
  end
end
