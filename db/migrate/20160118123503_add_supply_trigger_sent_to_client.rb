class AddSupplyTriggerSentToClient < ActiveRecord::Migration
  def change
    add_column :clients, :supply_trigger_sent, :boolean
  end
end
