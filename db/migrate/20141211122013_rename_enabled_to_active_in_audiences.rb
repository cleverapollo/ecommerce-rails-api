class RenameEnabledToActiveInAudiences < ActiveRecord::Migration
  def change
    rename_column :audiences, :enabled, :active
  end
end
