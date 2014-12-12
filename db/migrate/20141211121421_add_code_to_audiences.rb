class AddCodeToAudiences < ActiveRecord::Migration
  def change
    add_column :audiences, :code, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :audiences, :code, unique: true
  end
end
