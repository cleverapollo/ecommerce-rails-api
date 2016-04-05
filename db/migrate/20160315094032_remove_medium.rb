class RemoveMedium < ActiveRecord::Migration
  def change
    drop_table :articles
    drop_table :medium_actions
  end
end
