class AddDontDisturbUntilToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :dont_disturb_until, :timestamp
  end
end
