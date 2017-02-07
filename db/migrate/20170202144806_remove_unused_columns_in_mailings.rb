class RemoveUnusedColumnsInMailings < ActiveRecord::Migration
  def up
    remove_column :mailings_settings, :template_type

    remove_column :trigger_mailings, :image_width
    remove_column :trigger_mailings, :image_height

    remove_column :digest_mailings, :image_width
    remove_column :digest_mailings, :image_height
  end

  def down
    add_column :mailings_settings, :template_type, :integer, default: 1
    add_column :trigger_mailings, :image_width, :integer, default: 180
    add_column :trigger_mailings, :image_height, :integer, default: 180
    add_column :digest_mailings, :image_width, :integer, default: 180
    add_column :digest_mailings, :image_height, :integer, default: 180
  end
end


