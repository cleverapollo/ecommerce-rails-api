class AddCategoriesToTables < ActiveRecord::Migration
  def change
    add_column :items, :categories, :string, array: true, default: []
    execute <<-SQL
      update items set categories = ARRAY[category_uniqid] where category_uniqid is not null and category_uniqid != '';
    SQL

    add_column :actions, :categories, :string, array: true, default: []
    Action.find_in_batches do |batch|
      Action.connection.execute("
        UPDATE actions 
        SET categories = ARRAY[category_uniqid] 
        WHERE category_uniqid is not null AND category_uniqid != ''
        AND id IN (#{batch.map(&:id).join(',')})
      ")
    end
  end
end
