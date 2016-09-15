class CreateVisits < ActiveRecord::Migration
  def change
    create_table :visits do |t|
      t.date :date, null: false
      t.integer :user_id, limit: 8, null: false
      t.integer :shop_id, null: false
      t.integer :pages, null: false, default: 1
    end
    add_index :visits, [:date, :user_id, :shop_id], unique: true
    add_index :visits, [:shop_id, :date]
  end
end
