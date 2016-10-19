class AddAutoToItem < ActiveRecord::Migration
  def change
    add_column :items, :is_auto, :boolean
    add_column :items, :auto_compatibility, :jsonb
    add_column :items, :auto_periodic, :boolean
    add_column :items, :auto_vds, :text, array: true
    add_index :items, ['is_auto'], where: '((is_available = true) AND (ignored = false))'
  end
end
