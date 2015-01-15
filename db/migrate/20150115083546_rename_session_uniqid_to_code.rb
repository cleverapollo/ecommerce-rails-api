class RenameSessionUniqidToCode < ActiveRecord::Migration
  def change
    rename_column :sessions, :uniqid, :code
  end
end
