class CreateRtbPropellers < ActiveRecord::Migration
  def change
    create_table :rtb_propellers do |t|
      t.string :code
      t.timestamps null: false
    end
    add_index :rtb_propellers, :code, unique: true
  end
end
