class PreferenceForMahoutAction < ActiveRecord::Migration
  def change
    add_column :mahout_actions, :preference, :float
  end
end
