class MergeAudiencesIntoShopsUsers < ActiveRecord::Migration
  def change
    add_column :shops_users, :digests_enabled, :boolean, null: false, default: true
    add_column :shops_users, :code, :uuid, default: "uuid_generate_v4()"
    add_index :shops_users, :code, unique: true
  end
end
