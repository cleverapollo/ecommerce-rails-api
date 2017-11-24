class MoveDataScript < ActiveRecord::Migration
  disable_ddl_transaction!

  def up

    begin
      add_column :vendor_campaigns, :filters, :jsonb, null: false, default: {}
    rescue Exception => e
      puts e
    end

    %w(active_admin_comments advertiser_vendors advertisers brand_campaign_item_categories brand_campaign_purchases brand_campaigns brands categories cmses cpa_invoices currencies customer_balance_histories customers digest_mail_statistics employees industries insales_shops instant_auth_tokens invalid_emails ipn_messages leads mail_ru_audience_pools monthly_statistic_items monthly_statistics partner_rewards recommender_statistics requisites rewards segments shop_days_statistics shop_images shop_inventories shop_inventory_banners shop_statistics shopify_shops shops styles subscription_invoices subscription_plans theme_purchases themes transactions trigger_mail_statistics user_taxonomies vendor_campaigns vendor_shops vendors wear_type_dictionaries web_push_packet_purchases wizard_configurations).each do |table|
      exists = ActiveRecord::Base.connection.select_rows <<-SQL
        SELECT EXISTS (
           SELECT 1
           FROM   information_schema.tables
           WHERE  table_schema = 'public'
           AND    table_name = '#{table}_master'
           );
      SQL
      if exists.try(:first).try(:first)
        DataManager::MoveData.move(table)
      end
    end
  end

  def down

  end
end
