class AddRefererToClientErrors < ActiveRecord::Migration
  def change
    add_column :client_errors, :referer, :string
  end
end
