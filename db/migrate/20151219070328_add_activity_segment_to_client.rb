class AddActivitySegmentToClient < ActiveRecord::Migration
  def change
    add_column :clients, :activity_segment, :integer
    add_index :clients, [:shop_id, :activity_segment], where: ('activity_segment is not null')
  end
end
