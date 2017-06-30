class DropForeignTables < ActiveRecord::Migration
  def up
    execute 'DROP FOREIGN TABLE IF EXISTS rtb_jobs_master CASCADE;'
    execute 'DROP FOREIGN TABLE IF EXISTS rtb_internal_impressions_master CASCADE;'
    execute 'DROP FOREIGN TABLE IF EXISTS rtb_bid_requests_master CASCADE;'
    execute 'DROP FOREIGN TABLE IF EXISTS rtb_impressions_master CASCADE;'
  end
  def down

  end
end
