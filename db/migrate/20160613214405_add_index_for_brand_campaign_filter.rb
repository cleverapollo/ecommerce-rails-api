class AddIndexForBrandCampaignFilter < ActiveRecord::Migration
  def change
    add_column :items, :brand_downcase, :string
    add_index "items", [:brand_downcase], name: "index_items_on_brand_for_brand_campaign", where: "(brand_downcase IS NOT NULL and category_ids is not null)", using: :btree
  end
end
