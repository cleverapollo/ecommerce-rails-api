class AddGenderIndexToItem < ActiveRecord::Migration
  def change
    add_index :items, [:shop_id, :gender], where: '((is_available = true) AND (ignored = false))'
  end
end
