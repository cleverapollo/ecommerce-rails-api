class AddUnsubscribeMessage < ActiveRecord::Migration
  def change
    add_column :mailings_settings, :unsubscribe_message, :string
  end
end
