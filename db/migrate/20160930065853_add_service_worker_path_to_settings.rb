class AddServiceWorkerPathToSettings < ActiveRecord::Migration
  def change
    add_column :web_push_subscriptions_settings, :service_worker_path, :string
  end
end
