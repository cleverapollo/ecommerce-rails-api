class EditVolumeFieldItem < ActiveRecord::Migration
  def change
    remove_column :items, :volume
    add_column :items, :volume, :jsonb
  end
end
