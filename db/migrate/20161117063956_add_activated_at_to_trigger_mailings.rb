class AddActivatedAtToTriggerMailings < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :activated_at, :datetime
  end
end
