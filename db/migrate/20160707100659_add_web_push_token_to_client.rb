class AddWebPushTokenToClient < ActiveRecord::Migration
  def change
    add_column :clients, :web_push_token, :string
    add_column :clients, :web_push_browser, :string
    add_column :clients, :web_push_enabled, :boolean
    add_column :clients, :last_web_push_sent_at, :datetime
    add_index :clients, [:shop_id, :web_push_enabled], where: '(web_push_enabled is true)'
    add_index :clients, [:shop_id, :web_push_enabled, :last_web_push_sent_at], where: '(web_push_enabled is true and last_web_push_sent_at is not null)', name: 'index_clients_last_web_push_sent_at'
  end
end
