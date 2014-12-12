class RenameUnsubscribeTokenToCodeInSubscriptions < ActiveRecord::Migration
  def change
    rename_column :subscriptions, :unsubscribe_token, :code
  end
end
