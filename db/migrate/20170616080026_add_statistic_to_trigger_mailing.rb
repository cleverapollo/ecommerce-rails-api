class AddStatisticToTriggerMailing < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :statistic, :jsonb
  end
end
