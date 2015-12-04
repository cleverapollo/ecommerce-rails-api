class CreateNewIndexOnItems < ActiveRecord::Migration
  def self.up
    execute "END" # lol http://stackoverflow.com/questions/9622924/how-to-stop-rails-3-1-migration-from-running-in-a-transaction
    add_index :items, [:shop_id, :uniqid], unique: true, using: :btree, algorithm: :concurrently
    execute "BEGIN"
  end
end
