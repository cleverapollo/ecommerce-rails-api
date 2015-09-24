class AddBarcodeToItems < ActiveRecord::Migration
  def change
    add_column :items, :barcode, :string, :limit=>1914
  end
end
