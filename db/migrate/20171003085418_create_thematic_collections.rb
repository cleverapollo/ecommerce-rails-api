class CreateThematicCollections < ActiveRecord::Migration
  def change
    create_table :thematic_collections do |t|
      t.references :shop
      t.string :name
      t.text :keywords
      t.timestamps null: false
    end
  end
end
