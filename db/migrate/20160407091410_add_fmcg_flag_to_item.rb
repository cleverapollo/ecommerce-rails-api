class AddFmcgFlagToItem < ActiveRecord::Migration
  def change
    add_column :items, :is_fmcg, :boolean
  end
end
