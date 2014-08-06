class AddSimilarIndex < ActiveRecord::Migration
  def change
    execute <<-SQL
      create index similar_index on actions (shop_id, item_id, timestamp); analyze actions;
    SQL
  end
end
