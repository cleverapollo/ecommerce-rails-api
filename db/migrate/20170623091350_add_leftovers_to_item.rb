class AddLeftoversToItem < ActiveRecord::Migration
  def change
    add_column :items, :leftovers, :string
  end
end
