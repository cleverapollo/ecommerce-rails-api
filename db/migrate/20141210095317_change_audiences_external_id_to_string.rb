class ChangeAudiencesExternalIdToString < ActiveRecord::Migration
  def change
    change_column :audiences, :external_id, :string, null: false
  end
end
