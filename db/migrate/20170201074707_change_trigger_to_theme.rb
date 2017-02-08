class ChangeTriggerToTheme < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :theme_id, :integer, limit: 8
    add_column :trigger_mailings, :theme_type, :string
    add_column :trigger_mailings, :template_data, :jsonb
    add_index :trigger_mailings, [:shop_id, :theme_id, :theme_type], name: 'index_trigger_mailings_theme'
  end
end
