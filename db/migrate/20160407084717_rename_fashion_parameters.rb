class RenameFashionParameters < ActiveRecord::Migration
  def change
    rename_column :items, :gender, :fashion_gender
    rename_column :items, :sizes, :fashion_sizes
    rename_column :items, :wear_type, :fashion_wear_type
    rename_column :items, :feature, :fashion_feature
    rename_column :items, :volume, :fmcg_volume
    rename_column :items, :periodic, :fmcg_periodic
    rename_column :items, :hypoallergenic, :fmcg_hypoallergenic
  end
end
