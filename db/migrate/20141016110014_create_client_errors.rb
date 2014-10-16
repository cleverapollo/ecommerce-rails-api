class CreateClientErrors < ActiveRecord::Migration
  def change
    create_table :client_errors do |t|
      t.integer :shop_id
      t.string :exception_class, null: false
      t.string :exception_message, null: false
      t.text :params, null: false
      t.boolean :resolved, null: false, default: false

      t.timestamps
    end
    add_index :client_errors, :shop_id, where: 'resolved = false'
  end
end
