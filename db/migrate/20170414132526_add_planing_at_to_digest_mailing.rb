class AddPlaningAtToDigestMailing < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :planing_at, :datetime
  end
end
