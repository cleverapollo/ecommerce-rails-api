class CreateMailings < ActiveRecord::Migration
  def change
    create_table :mailings do |t|
      t.integer :shop_id, null: false
      t.string :token, null: false
      t.text :delivery_settings, null: false
      t.text :items, null: false
      t.timestamps
    end

    add_index :mailings, :token, unique: true
  end
end
