class AddCompensatedToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :compensated, :boolean
  end
end
