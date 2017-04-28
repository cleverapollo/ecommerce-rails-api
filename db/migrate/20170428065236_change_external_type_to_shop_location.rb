class ChangeExternalTypeToShopLocation < ActiveRecord::Migration
  def change
    change_column :shop_locations, :external_type, :string, null: true
  end
end
