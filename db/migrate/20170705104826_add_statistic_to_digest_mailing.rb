class AddStatisticToDigestMailing < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :statistic, :jsonb
  end
end
