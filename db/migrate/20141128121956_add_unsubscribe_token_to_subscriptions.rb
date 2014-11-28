class AddUnsubscribeTokenToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :unsubscribe_token, :uuid, null: false, default: 'uuid_generate_v4()'
  end
end
