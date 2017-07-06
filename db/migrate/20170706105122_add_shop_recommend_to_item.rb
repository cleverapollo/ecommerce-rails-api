class AddShopRecommendToItem < ActiveRecord::Migration
  def change
    add_column :items, :shop_recommend, :string, array: true
  end
end
