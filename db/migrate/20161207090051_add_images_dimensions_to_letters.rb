class AddImagesDimensionsToLetters < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :images_dimension, :integer, default: 3
    add_column :digest_mailings, :images_dimension, :integer, default: 3
  end
end
