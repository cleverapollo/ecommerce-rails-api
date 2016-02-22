class CreateTsumSegments < ActiveRecord::Migration
  def change
    create_table :tsum_segments do |t|
      t.string :code, null: false
      t.string :segment, null: false
    end
    add_index :tsum_segments, [:code, :segment], unique: true
    add_index :tsum_segments, :code
  end
end
