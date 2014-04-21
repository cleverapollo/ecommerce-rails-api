class AddAdditionalFieldsToItems < ActiveRecord::Migration
  def change
    add_column :items, :name, :string
    add_column :items, :description, :text
    add_column :items, :url, :string
    add_column :items, :image_url, :string
    add_column :items, :tags, :string, array: true, default: '{}'
    add_column :items, :widgetable, :boolean, default: false, null: false
  end
end
