class CreateThematicCollectionSections < ActiveRecord::Migration
  def change
    create_table :thematic_collection_sections do |t|
      t.references :shop
      t.references :thematic_collection
      t.text :rules
      t.string :name
      t.timestamps null: false
    end
  end
end
