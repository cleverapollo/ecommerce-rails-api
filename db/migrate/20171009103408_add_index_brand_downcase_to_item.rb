class AddIndexBrandDowncaseToItem < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index "items", ["shop_id", "brand_downcase", "id"], name: "index_items_on_shop_and_brand_downcase", where: "((is_available = true) AND (ignored = false) AND (widgetable = true) AND (brand_downcase IS NOT NULL))", algorithm: :concurrently
  end
end
