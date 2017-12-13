class AddRealtyInToUsers < ActiveRecord::Migration
  def change
    add_column :users, :realty, :jsonb
  end
end
