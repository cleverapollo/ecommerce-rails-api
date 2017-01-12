class AddPetsFieldsToItems < ActiveRecord::Migration
  def change
    add_column :items, :is_pets, :boolean
    add_column :items, :pets_breed, :string
    add_column :items, :pets_type, :string
    add_column :items, :pets_age, :string
    add_column :items, :pets_periodic, :boolean
    add_column :items, :pets_size, :string
    add_index "items", ["is_pets"], where: "((is_available = true) AND (ignored = false))", using: :btree
    add_index "items", ["pets_breed"], where: "is_pets IS TRUE AND pets_breed IS NOT NULL", using: :btree
    add_index "items", ["pets_type"], where: "is_pets IS TRUE AND pets_type IS NOT NULL", using: :btree
    add_index "items", ["pets_age"], where: "is_pets IS TRUE AND pets_age IS NOT NULL", using: :btree
    add_index "items", ["pets_size"], where: "is_pets IS TRUE AND pets_size IS NOT NULL", using: :btree
  end
end
