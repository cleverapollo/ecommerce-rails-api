class CreateBeaconMessages < ActiveRecord::Migration
  def change
    create_table :beacon_messages do |t|
      t.references :shop
      t.references :user
      t.references :session
      t.text :params, null: false
      t.boolean :notified, null: false, default: false

      t.timestamps
    end
  end
end
