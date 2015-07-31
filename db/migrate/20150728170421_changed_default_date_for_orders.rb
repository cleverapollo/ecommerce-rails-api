class ChangedDefaultDateForOrders < ActiveRecord::Migration
  def up
    change_column_default(:orders, :date, nil)
  end

  def down

  end
end
