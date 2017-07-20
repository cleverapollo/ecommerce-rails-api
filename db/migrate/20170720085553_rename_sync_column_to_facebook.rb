class RenameSyncColumnToFacebook < ActiveRecord::Migration
  def change
    add_column :sessions, :synced_with_facebook_at, :date
    remove_column :sessions, :synced_with_amber_at
    remove_column :sessions, :synced_with_dca_at
    remove_column :sessions, :synced_with_aidata_at
    remove_column :sessions, :synced_with_auditorius_at
    remove_column :sessions, :synced_with_mailru_at
    remove_column :sessions, :synced_with_relapio_at

  end
end
