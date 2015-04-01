class AddRecommendedAtToActions < ActiveRecord::Migration
  def change
    add_column :actions, :recommended_at, :timestamp

    Action.reset_column_information

    Action.where('view_date >= ?', 2.weeks.ago).where('recommended_by IS NOT NULL').update_all(recommended_at: Time.current)
  end
end
