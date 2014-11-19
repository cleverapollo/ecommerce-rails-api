class CreateAudiences < ActiveRecord::Migration
  def change
    create_table :audiences do |t|
      t.integer :shop_id,           null: false
      t.integer :external_id,       null: false
      t.integer :user_id
      t.string  :email,             null: false
      t.boolean :enabled,           null: false, default: true
      t.text    :custom_attributes
    end

    add_index :audiences, [:external_id, :shop_id], unique: true
    add_index :audiences, :user_id
  end
end
