class CreateRecommendationsRequests < ActiveRecord::Migration
  def change
    create_table :recommendations_requests do |t|
      t.integer :shop_id, null: false
      t.integer :branch_id, null: false
      t.string :recommender_type, null: false
      t.boolean :clicked, null: false, default: false
      t.integer :recommendations_count, null: false
      t.string :recommended_ids, array: true, null: false, default: []
      t.decimal :duration, null: false
      t.integer :user_id, null: false
      t.string :session_code

      t.timestamps
    end
  end
end
