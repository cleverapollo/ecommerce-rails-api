class AddEmailConfirmedToClients < ActiveRecord::Migration
  def change
    add_column :clients, :email_confirmed, :boolean
  end
end
