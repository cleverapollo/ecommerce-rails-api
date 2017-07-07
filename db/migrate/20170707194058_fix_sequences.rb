class FixSequences < ActiveRecord::Migration
  def change
    execute <<-SQL
    ALTER TABLE recommendations_requests ALTER COLUMN id SET DEFAULT generate_next_recommendations_request_id();
    ALTER TABLE interactions ALTER COLUMN id SET DEFAULT generate_next_interaction_id();
    SQL
  end
end
