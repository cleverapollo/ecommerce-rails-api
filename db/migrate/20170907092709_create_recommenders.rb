class CreateRecommenders < ActiveRecord::Migration
  def change
    create_table :recommenders do |t|
      t.references :shop
      t.string :name, null: false
      t.string :description
      t.integer :limit, default: 6, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: true
      t.jsonb :rules

      t.timestamps null: false
    end

    add_index :recommenders, [:shop_id, :code], unique: true
  end
end
