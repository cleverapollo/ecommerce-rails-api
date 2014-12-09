class AddStartFinishTimesToDigestMailings < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :started_at, :timestamp
    add_column :digest_mailings, :finished_at, :timestamp
  end
end
