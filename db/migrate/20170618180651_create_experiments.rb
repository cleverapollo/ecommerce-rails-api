class CreateExperiments < ActiveRecord::Migration
  def change
    create_table :experiments do |t|
      t.integer :shop_id, null: false
      t.string :name, null: false
      t.integer :segments, null: false, default: 2
      t.boolean :active, default: false
      t.timestamps null: false
    end
  end
end
