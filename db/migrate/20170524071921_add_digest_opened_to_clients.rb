class AddDigestOpenedToClients < ActiveRecord::Migration
  def change
    add_column :clients, :digest_opened, :boolean
  end
end
