class AddRecommendedItemsToMailings < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :amount_of_recommended_items, :integer, default: 9, null: false
    add_column :trigger_mailings, :amount_of_recommended_items, :integer, default: 9, null: false
  end
end
