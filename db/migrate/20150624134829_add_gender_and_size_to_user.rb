class AddGenderAndSizeToUser < ActiveRecord::Migration
  def change
    add_column :users, :gender, :jsonb, default: '{"m":50, "f":50}', null: false

    add_column :users, :size, :jsonb, default: '{}', null: false
  end
end
