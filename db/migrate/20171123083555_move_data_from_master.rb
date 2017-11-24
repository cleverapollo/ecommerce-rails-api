class MoveDataFromMaster < ActiveRecord::Migration
  def up

    # Создаем внешнюю таблицу с мастера
    config_master = ActiveRecord::Base.configurations["#{Rails.env}_master"]
    config = ActiveRecord::Base.configurations["#{Rails.env}"]
    if Rails.env.development?
      execute <<-SQL
        CREATE EXTENSION IF NOT EXISTS postgres_fdw;
        DROP USER MAPPING IF EXISTS FOR #{config['username']} SERVER master_server;
        DROP SERVER IF EXISTS master_server CASCADE;
        CREATE SERVER master_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '#{config_master["host"] == "localhost" ? "127.0.0.1" : config_master["host"]}', port '#{config_master["port"] || 5432}', dbname '#{config_master["database"]}');
        CREATE USER MAPPING FOR #{config['username']} SERVER master_server OPTIONS (user '#{config_master["username"]}', password '#{config_master["password"]}');
      SQL
    end

    create_table "active_admin_comments", force: :cascade do |t|
      t.string   "namespace",     limit: 255
      t.text     "body"
      t.string   "resource_id",   limit: 255, null: false
      t.string   "resource_type", limit: 255, null: false
      t.integer  "author_id"
      t.string   "author_type",   limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE active_admin_comments_master (
        id integer NOT NULL default nextval('active_admin_comments_id_seq'::regclass),
        namespace character varying(255),
        body text,
        resource_id character varying(255) NOT NULL,
        resource_type character varying(255) NOT NULL,
        author_id integer,
        author_type character varying(255),
        created_at timestamp without time zone,
        updated_at timestamp without time zone
    ) INHERITS(active_admin_comments) SERVER master_server OPTIONS(table_name 'active_admin_comments');
    SELECT setval('active_admin_comments_id_seq', COALESCE((SELECT MAX(id) FROM active_admin_comments_master) + 1, 1), false);
    SQL


    create_table "advertiser_vendors", force: :cascade do |t|
      t.integer  "advertiser_id"
      t.integer  "vendor_id"
      t.datetime "created_at",    null: false
      t.datetime "updated_at",    null: false
    end
    add_index "advertiser_vendors", ["vendor_id", "advertiser_id"], name: "index_advertiser_vendors_on_vendor_id_and_advertiser_id", unique: true, using: :btree
    execute <<-SQL
      CREATE FOREIGN TABLE advertiser_vendors_master (
          id integer NOT NULL default nextval('advertiser_vendors_id_seq'::regclass),
          advertiser_id integer,
          vendor_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      ) INHERITS(advertiser_vendors) SERVER master_server OPTIONS(table_name 'advertiser_vendors');
    SELECT setval('advertiser_vendors_id_seq', COALESCE((SELECT MAX(id) FROM advertiser_vendors_master) + 1, 1), false);
    SQL


    create_table "advertisers", force: :cascade do |t|
      t.string   "email"
      t.string   "encrypted_password",     default: "",  null: false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",          default: 0,   null: false
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.inet     "current_sign_in_ip"
      t.inet     "last_sign_in_ip"
      t.string   "first_name"
      t.string   "last_name"
      t.string   "company"
      t.string   "website"
      t.string   "mobile_phone"
      t.string   "work_phone"
      t.string   "country"
      t.string   "city"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.float    "balance",                default: 0.0, null: false
      t.string   "brand"
    end
    add_index "advertisers", ["email"], name: "index_advertisers_on_email", unique: true, using: :btree
    add_index "advertisers", ["reset_password_token"], name: "index_advertisers_on_reset_password_token", unique: true, using: :btree
    execute <<-SQL
      CREATE FOREIGN TABLE advertisers_master (
          id integer NOT NULL default nextval('advertisers_id_seq'::regclass),
          email character varying,
          encrypted_password character varying DEFAULT ''::character varying NOT NULL,
          reset_password_token character varying,
          reset_password_sent_at timestamp without time zone,
          remember_created_at timestamp without time zone,
          sign_in_count integer DEFAULT 0 NOT NULL,
          current_sign_in_at timestamp without time zone,
          last_sign_in_at timestamp without time zone,
          current_sign_in_ip inet,
          last_sign_in_ip inet,
          first_name character varying,
          last_name character varying,
          company character varying,
          website character varying,
          mobile_phone character varying,
          work_phone character varying,
          country character varying,
          city character varying,
          created_at timestamp without time zone,
          updated_at timestamp without time zone,
          balance double precision DEFAULT 0 NOT NULL,
          brand character varying
      ) INHERITS(advertisers) SERVER master_server OPTIONS(table_name 'advertisers');
    SELECT setval('advertisers_id_seq', COALESCE((SELECT MAX(id) FROM advertisers_master) + 1, 1), false);
    SQL


    execute <<-SQL
    CREATE TABLE ar_internal_metadata (
        key character varying NOT NULL,
        value character varying,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    );
    ALTER TABLE ONLY ar_internal_metadata
        ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);
    CREATE FOREIGN TABLE ar_internal_metadata_master (
        key character varying NOT NULL,
        value character varying,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    ) INHERITS(ar_internal_metadata) SERVER master_server OPTIONS(table_name 'ar_internal_metadata');
    SQL


    create_table "brand_campaign_item_categories", force: :cascade do |t|
      t.integer  "item_category_id",  limit: 8
      t.datetime "created_at",                  null: false
      t.datetime "updated_at",                  null: false
      t.integer  "brand_campaign_id"
    end
    add_index "brand_campaign_item_categories", ["brand_campaign_id"], name: "index_brand_campaign_item_categories_on_brand_campaign_id", using: :btree
    add_index "brand_campaign_item_categories", ["item_category_id"], name: "index_brand_campaign_item_categories_on_item_category_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE brand_campaign_item_categories_master (
        id integer NOT NULL default nextval('brand_campaign_item_categories_id_seq'::regclass),
        item_category_id bigint,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        brand_campaign_id integer
    ) INHERITS(brand_campaign_item_categories) SERVER master_server OPTIONS(table_name 'brand_campaign_item_categories');
    SELECT setval('brand_campaign_item_categories_id_seq', COALESCE((SELECT MAX(id) FROM brand_campaign_item_categories_master) + 1, 1), false);
    SQL


    create_table "brand_campaign_purchases", force: :cascade do |t|
      t.integer  "item_id",           limit: 8
      t.integer  "shop_id"
      t.integer  "order_id",          limit: 8
      t.float    "price"
      t.string   "recommended_by"
      t.date     "date"
      t.datetime "created_at",                  null: false
      t.datetime "updated_at",                  null: false
      t.integer  "brand_campaign_id"
    end
    add_index "brand_campaign_purchases", ["brand_campaign_id", "shop_id"], name: "index_brand_campaign_purchases_on_brand_campaign_id_and_shop_id", using: :btree
    add_index "brand_campaign_purchases", ["brand_campaign_id"], name: "index_brand_campaign_purchases_on_brand_campaign_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE brand_campaign_purchases_master (
        id integer NOT NULL default nextval('brand_campaign_purchases_id_seq'::regclass),
        item_id bigint,
        shop_id integer,
        order_id bigint,
        price double precision,
        recommended_by character varying,
        date date,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        brand_campaign_id integer
    ) INHERITS(brand_campaign_purchases) SERVER master_server OPTIONS(table_name 'brand_campaign_purchases');
    SELECT setval('brand_campaign_purchases_id_seq', COALESCE((SELECT MAX(id) FROM brand_campaign_purchases_master) + 1, 1), false);
    SQL


    create_table "brand_campaigns", force: :cascade do |t|
      t.integer  "advertiser_id"
      t.float    "balance",               default: 0.0,   null: false
      t.integer  "cpm",                   default: 1500,  null: false
      t.string   "brand",                                 null: false
      t.string   "downcase_brand",                        null: false
      t.boolean  "campaign_launched",     default: false, null: false
      t.integer  "priority",              default: 100,   null: false
      t.float    "cpc",                   default: 10.0,  null: false
      t.boolean  "is_expansion",          default: false
      t.integer  "campaign_type",         default: 1
      t.datetime "created_at",                            null: false
      t.datetime "updated_at",                            null: false
      t.integer  "product_minimum_price", default: 0,     null: false
      t.boolean  "in_all_categories",     default: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE brand_campaigns_master (
        id integer NOT NULL  default nextval('brand_campaigns_id_seq'::regclass),
        advertiser_id integer,
        balance double precision DEFAULT 0.0 NOT NULL,
        cpm integer DEFAULT 1500 NOT NULL,
        brand character varying NOT NULL,
        downcase_brand character varying NOT NULL,
        campaign_launched boolean DEFAULT false NOT NULL,
        priority integer DEFAULT 100 NOT NULL,
        cpc double precision DEFAULT 10.0 NOT NULL,
        is_expansion boolean DEFAULT false,
        campaign_type integer DEFAULT 1,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        product_minimum_price integer DEFAULT 0 NOT NULL,
        in_all_categories boolean DEFAULT false
    ) INHERITS(brand_campaigns) SERVER master_server OPTIONS(table_name 'brand_campaigns');
    SELECT setval('brand_campaigns_id_seq', COALESCE((SELECT MAX(id) FROM brand_campaigns_master) + 1, 1), false);
    SQL


    create_table "brands", force: :cascade do |t|
      t.string   "name"
      t.string   "keyword"
      t.text     "comment"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE brands_master (
        id integer NOT NULL default nextval('brands_id_seq'::regclass),
        name character varying,
        keyword character varying,
        comment text,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    ) INHERITS(brands) SERVER master_server OPTIONS(table_name 'brands');
    SELECT setval('brands_id_seq', COALESCE((SELECT MAX(id) FROM brands_master) + 1, 1), false);
    SQL


    create_table "categories", force: :cascade do |t|
      t.string   "name",            limit: 255
      t.boolean  "deletable",                   default: true, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "code",            limit: 255,                null: false
      t.decimal  "increase_units"
      t.decimal  "increase_rubles"
      t.string   "taxonomy"
    end
    add_index "categories", ["code"], name: "index_categories_on_code", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE categories_master (
        id integer NOT NULL default nextval('categories_id_seq'::regclass),
        name character varying(255),
        deletable boolean DEFAULT true NOT NULL,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        code character varying(255) NOT NULL,
        increase_units numeric,
        increase_rubles numeric,
        taxonomy character varying
    ) INHERITS(categories) SERVER master_server OPTIONS(table_name 'categories');
    SELECT setval('categories_id_seq', COALESCE((SELECT MAX(id) FROM categories_master) + 1, 1), false);
    SQL


    create_table "cmses", force: :cascade do |t|
      t.string   "code",               limit: 255,                 null: false
      t.string   "name",               limit: 255,                 null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "supported",                      default: false, null: false
      t.string   "documentation_link", limit: 255
    end
    execute <<-SQL
    CREATE FOREIGN TABLE cmses_master (
        id integer NOT NULL default nextval('cmses_id_seq'::regclass),
        code character varying(255) NOT NULL,
        name character varying(255) NOT NULL,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        supported boolean DEFAULT false NOT NULL,
        documentation_link character varying(255)
    )  INHERITS(cmses) SERVER master_server OPTIONS(table_name 'cmses');
    SELECT setval('cmses_id_seq', COALESCE((SELECT MAX(id) FROM cmses_master) + 1, 1), false);
    SQL


    create_table "cpa_invoices", force: :cascade do |t|
      t.integer "shop_id"
      t.date    "date"
      t.float   "amount"
    end
    add_index "cpa_invoices", ["shop_id", "date"], name: "index_cpa_invoices_on_shop_id_and_date", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE cpa_invoices_master (
        id integer NOT NULL default nextval('cpa_invoices_id_seq'::regclass),
        shop_id integer,
        date date,
        amount double precision
    )  INHERITS(cpa_invoices) SERVER master_server OPTIONS(table_name 'cpa_invoices');
    SELECT setval('cpa_invoices_id_seq', COALESCE((SELECT MAX(id) FROM cpa_invoices_master) + 1, 1), false);
    SQL


    create_table "currencies", force: :cascade do |t|
      t.string   "code",                                  null: false
      t.string   "symbol",                                null: false
      t.datetime "created_at",                            null: false
      t.datetime "updated_at",                            null: false
      t.integer  "min_payment",           default: 500,   null: false
      t.float    "exchange_rate",         default: 1.0,   null: false
      t.boolean  "payable",               default: false
      t.boolean  "stripe_paid",           default: false, null: false
      t.float    "remarketing_min_price", default: 0.0,   null: false
    end
    add_index "currencies", ["stripe_paid"], name: "index_currencies_on_stripe_paid", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE currencies_master (
        id integer NOT NULL default nextval('currencies_id_seq'::regclass),
        code character varying NOT NULL,
        symbol character varying NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        min_payment integer DEFAULT 500 NOT NULL,
        exchange_rate double precision DEFAULT 1.0 NOT NULL,
        payable boolean DEFAULT false,
        stripe_paid boolean DEFAULT false NOT NULL,
        remarketing_min_price double precision DEFAULT 0.0 NOT NULL
    )  INHERITS(currencies) SERVER master_server OPTIONS(table_name 'currencies');
    SELECT setval('currencies_id_seq', COALESCE((SELECT MAX(id) FROM currencies_master) + 1, 1), false);
    SQL


    create_table "customer_balance_histories", force: :cascade do |t|
      t.integer  "customer_id"
      t.string   "message"
      t.datetime "created_at",  null: false
      t.datetime "updated_at",  null: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE customer_balance_histories_master (
        id integer NOT NULL default nextval('customer_balance_histories_id_seq'::regclass),
        customer_id integer,
        message character varying,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(customer_balance_histories) SERVER master_server OPTIONS(table_name 'customer_balance_histories');
    SELECT setval('customer_balance_histories_id_seq', COALESCE((SELECT MAX(id) FROM customer_balance_histories_master) + 1, 1), false);
    SQL


    create_table "customers", force: :cascade do |t|
      t.string   "email",                  limit: 255, default: "",       null: false
      t.string   "encrypted_password",     limit: 255, default: "",       null: false
      t.string   "reset_password_token",   limit: 255
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                      default: 0,        null: false
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip",     limit: 255
      t.string   "last_sign_in_ip",        limit: 255
      t.integer  "role",                               default: 1
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "phone",                  limit: 255
      t.string   "city",                   limit: 255
      t.string   "company",                limit: 255
      t.boolean  "subscribed",                         default: true,     null: false
      t.string   "unsubscribe_token",      limit: 255
      t.integer  "partner_id"
      t.string   "first_name",             limit: 255
      t.string   "last_name",              limit: 255
      t.float    "balance",                            default: 0.0,      null: false
      t.string   "gift_link",              limit: 255
      t.boolean  "real",                               default: true
      t.boolean  "financial_manager",                  default: false
      t.date     "recent_activity"
      t.string   "promocode"
      t.string   "juridical_person"
      t.integer  "currency_id",                        default: 1,        null: false
      t.string   "language",                           default: "en",     null: false
      t.boolean  "notify_about_finances",              default: true,     null: false
      t.integer  "partner_balance",                    default: 0,        null: false
      t.integer  "my_partner_visits",                  default: 0
      t.integer  "my_partner_signups",                 default: 0
      t.string   "api_key",                limit: 255
      t.string   "api_secret",             limit: 255
      t.string   "quick_sign_in_token"
      t.datetime "confirmed_at"
      t.string   "stripe_customer_id"
      t.string   "stripe_card_last4"
      t.string   "stripe_card_id"
      t.string   "country_code"
      t.string   "time_zone",                          default: "Moscow", null: false
      t.boolean  "shopify",                            default: false,    null: false
    end
    add_index "customers", ["api_key", "api_secret"], name: "index_customers_on_api_key_and_api_secret", unique: true, using: :btree
    add_index "customers", ["email"], name: "index_customers_on_email", unique: true, using: :btree
    add_index "customers", ["quick_sign_in_token"], name: "index_customers_on_quick_sign_in_token", using: :btree
    add_index "customers", ["reset_password_token"], name: "index_customers_on_reset_password_token", unique: true, using: :btree
    add_index "customers", ["stripe_customer_id"], name: "index_customers_on_stripe_customer_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE customers_master (
        id integer NOT NULL default nextval('customers_id_seq'::regclass),
        email character varying(255) DEFAULT ''::character varying NOT NULL,
        encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
        reset_password_token character varying(255),
        reset_password_sent_at timestamp without time zone,
        remember_created_at timestamp without time zone,
        sign_in_count integer DEFAULT 0 NOT NULL,
        current_sign_in_at timestamp without time zone,
        last_sign_in_at timestamp without time zone,
        current_sign_in_ip character varying(255),
        last_sign_in_ip character varying(255),
        role integer DEFAULT 1,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        phone character varying(255),
        city character varying(255),
        company character varying(255),
        subscribed boolean DEFAULT true NOT NULL,
        unsubscribe_token character varying(255),
        partner_id integer,
        first_name character varying(255),
        last_name character varying(255),
        balance double precision DEFAULT 0 NOT NULL,
        gift_link character varying(255),
        "real" boolean DEFAULT true,
        financial_manager boolean DEFAULT false,
        recent_activity date,
        promocode character varying,
        juridical_person character varying,
        currency_id integer DEFAULT 1 NOT NULL,
        language character varying DEFAULT 'en'::character varying NOT NULL,
        notify_about_finances boolean DEFAULT true NOT NULL,
        partner_balance integer DEFAULT 0 NOT NULL,
        my_partner_visits integer DEFAULT 0,
        my_partner_signups integer DEFAULT 0,
        api_key character varying(255),
        api_secret character varying(255),
        quick_sign_in_token character varying,
        confirmed_at timestamp without time zone,
        time_zone character varying DEFAULT 'Moscow'::character varying NOT NULL,
        stripe_customer_id character varying,
        stripe_card_last4 character varying,
        stripe_card_id character varying,
        country_code character varying,
        shopify boolean DEFAULT false NOT NULL
    )  INHERITS(customers) SERVER master_server OPTIONS(table_name 'customers');
    SELECT setval('customers_id_seq', COALESCE((SELECT MAX(id) FROM customers_master) + 1, 1), false);
    SQL


    create_table "digest_mail_statistics", force: :cascade do |t|
      t.date     "date",                   null: false
      t.integer  "shop_id",                null: false
      t.integer  "opened",     default: 0, null: false
      t.integer  "clicked",    default: 0, null: false
      t.integer  "bounced",    default: 0, null: false
      t.integer  "sent",       default: 0, null: false
      t.datetime "created_at",             null: false
      t.datetime "updated_at",             null: false
    end

    add_index "digest_mail_statistics", ["date"], name: "index_digest_mail_statistics_on_date", using: :btree
    add_index "digest_mail_statistics", ["shop_id", "date"], name: "index_digest_mail_statistics_on_shop_id_and_date", unique: true, using: :btree
    add_index "digest_mail_statistics", ["shop_id"], name: "index_digest_mail_statistics_on_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE digest_mail_statistics_master (
        id integer NOT NULL default nextval('digest_mail_statistics_id_seq'::regclass),
        date date NOT NULL,
        shop_id integer NOT NULL,
        opened integer DEFAULT 0 NOT NULL,
        clicked integer DEFAULT 0 NOT NULL,
        bounced integer DEFAULT 0 NOT NULL,
        sent integer DEFAULT 0 NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(digest_mail_statistics) SERVER master_server OPTIONS(table_name 'digest_mail_statistics');
    SELECT setval('digest_mail_statistics_id_seq', COALESCE((SELECT MAX(id) FROM digest_mail_statistics_master) + 1, 1), false);
    SQL


    create_table "employees", force: :cascade do |t|
      t.integer  "customer_id",      null: false
      t.integer  "shop_id",          null: false
      t.integer  "head_customer_id", null: false
      t.datetime "created_at",       null: false
      t.datetime "updated_at",       null: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE employees_master (
        id integer NOT NULL default nextval('employees_id_seq'::regclass),
        customer_id integer NOT NULL,
        shop_id integer NOT NULL,
        head_customer_id integer NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(employees) SERVER master_server OPTIONS(table_name 'employees');
    SELECT setval('employees_id_seq', COALESCE((SELECT MAX(id) FROM employees_master) + 1, 1), false);
    SQL


    create_table "industries", force: :cascade do |t|
      t.string   "code",       null: false
      t.string   "channels",   null: false, array: true
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE industries_master (
        id integer NOT NULL default nextval('industries_id_seq'::regclass),
        code character varying NOT NULL,
        channels character varying[] NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(industries) SERVER master_server OPTIONS(table_name 'industries');
    SELECT setval('industries_id_seq', COALESCE((SELECT MAX(id) FROM industries_master) + 1, 1), false);
    SQL


    create_table "insales_shops", force: :cascade do |t|
      t.string   "token",        limit: 255
      t.string   "insales_shop", limit: 255
      t.string   "insales_id",   limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "shop_id"
    end
    add_index "insales_shops", ["shop_id"], name: "index_insales_shops_on_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE insales_shops_master (
        id integer NOT NULL default nextval('insales_shops_id_seq'::regclass),
        token character varying(255),
        insales_shop character varying(255),
        insales_id character varying(255),
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        shop_id integer
    )  INHERITS(insales_shops) SERVER master_server OPTIONS(table_name 'insales_shops');
    SELECT setval('insales_shops_id_seq', COALESCE((SELECT MAX(id) FROM insales_shops_master) + 1, 1), false);
    SQL


    create_table "instant_auth_tokens", force: :cascade do |t|
      t.integer "customer_id"
      t.string  "token"
      t.date    "date"
    end

    add_index "instant_auth_tokens", ["date"], name: "index_instant_auth_tokens_on_date", using: :btree
    add_index "instant_auth_tokens", ["token"], name: "index_instant_auth_tokens_on_token", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE instant_auth_tokens_master (
        id integer NOT NULL default nextval('instant_auth_tokens_id_seq'::regclass),
        customer_id integer,
        token character varying,
        date date
    )  INHERITS(instant_auth_tokens) SERVER master_server OPTIONS(table_name 'instant_auth_tokens');
    SELECT setval('instant_auth_tokens_id_seq', COALESCE((SELECT MAX(id) FROM instant_auth_tokens_master) + 1, 1), false);
    SQL


    create_table "invalid_emails", force: :cascade do |t|
      t.string   "email",      null: false
      t.string   "reason"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    add_index "invalid_emails", ["email"], name: "index_invalid_emails_on_email", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE invalid_emails_master (
        id integer NOT NULL default nextval('invalid_emails_id_seq'::regclass),
        email character varying NOT NULL,
        reason character varying,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(invalid_emails) SERVER master_server OPTIONS(table_name 'invalid_emails');
    SELECT setval('invalid_emails_id_seq', COALESCE((SELECT MAX(id) FROM invalid_emails_master) + 1, 1), false);
    SQL


    create_table "ipn_messages", force: :cascade do |t|
      t.text     "content",    null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    execute <<-SQL
    CREATE FOREIGN TABLE ipn_messages_master (
        id integer NOT NULL default nextval('ipn_messages_id_seq'::regclass),
        content text NOT NULL,
        created_at timestamp without time zone,
        updated_at timestamp without time zone
    )  INHERITS(ipn_messages) SERVER master_server OPTIONS(table_name 'ipn_messages');
    SELECT setval('ipn_messages_id_seq', COALESCE((SELECT MAX(id) FROM ipn_messages_master) + 1, 1), false);
    SQL


    create_table "leads", force: :cascade do |t|
      t.string   "first_name"
      t.string   "last_name"
      t.string   "email"
      t.string   "phone"
      t.string   "country"
      t.string   "city"
      t.string   "source"
      t.string   "comment"
      t.string   "website"
      t.string   "company"
      t.string   "position"
      t.boolean  "synced_with_crm",     default: false
      t.boolean  "success",             default: false
      t.boolean  "cancelled",           default: false
      t.datetime "created_at",                          null: false
      t.datetime "updated_at",                          null: false
      t.string   "cms"
      t.string   "preferred_time_from"
      t.string   "preferred_time_to"
      t.string   "time_zone"
      t.integer  "shop_id"
      t.integer  "customer_id"
      t.string   "utm_source"
      t.string   "utm_medium"
      t.string   "utm_campaign"
    end
    execute <<-SQL
    CREATE FOREIGN TABLE leads_master (
        id integer NOT NULL default nextval('leads_id_seq'::regclass),
        first_name character varying,
        last_name character varying,
        email character varying,
        phone character varying,
        country character varying,
        city character varying,
        source character varying,
        comment character varying,
        website character varying,
        company character varying,
        "position" character varying,
        synced_with_crm boolean DEFAULT false,
        success boolean DEFAULT false,
        cancelled boolean DEFAULT false,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        cms character varying,
        preferred_time_from character varying,
        preferred_time_to character varying,
        time_zone character varying,
        shop_id integer,
        customer_id integer,
        utm_source character varying,
        utm_medium character varying,
        utm_campaign character varying
    )  INHERITS(leads) SERVER master_server OPTIONS(table_name 'leads');
    SELECT setval('leads_id_seq', COALESCE((SELECT MAX(id) FROM leads_master) + 1, 1), false);
    SQL


    create_table "mail_ru_audience_pools", force: :cascade do |t|
      t.string "list"
      t.string "session"
    end

    add_index "mail_ru_audience_pools", ["list"], name: "index_mail_ru_audience_pools_on_list", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE mail_ru_audience_pools_master (
        id integer NOT NULL default nextval('mail_ru_audience_pools_id_seq'::regclass),
        list character varying,
        session character varying
    )  INHERITS(mail_ru_audience_pools) SERVER master_server OPTIONS(table_name 'mail_ru_audience_pools');
    SELECT setval('mail_ru_audience_pools_id_seq', COALESCE((SELECT MAX(id) FROM mail_ru_audience_pools_master) + 1, 1), false);
    SQL


    create_table "monthly_statistic_items", force: :cascade do |t|
      t.integer  "monthly_statistic_id",                         null: false
      t.string   "type_item",            limit: 255,             null: false
      t.integer  "value",                            default: 1, null: false
      t.integer  "entity_id"
      t.string   "entity_type",          limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "monthly_statistic_items", ["entity_id", "entity_type"], name: "index_monthly_statistic_items_on_entity_id_and_entity_type", using: :btree
    add_index "monthly_statistic_items", ["monthly_statistic_id"], name: "index_monthly_statistic_items_on_monthly_statistic_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE monthly_statistic_items_master (
        id integer NOT NULL default nextval('monthly_statistic_items_id_seq'::regclass),
        monthly_statistic_id integer NOT NULL,
        type_item character varying(255) NOT NULL,
        value integer DEFAULT 1 NOT NULL,
        entity_id integer,
        entity_type character varying(255),
        created_at timestamp without time zone,
        updated_at timestamp without time zone
    )  INHERITS(monthly_statistic_items) SERVER master_server OPTIONS(table_name 'monthly_statistic_items');
    SELECT setval('monthly_statistic_items_id_seq', COALESCE((SELECT MAX(id) FROM monthly_statistic_items_master) + 1, 1), false);
    SQL


    create_table "monthly_statistics", force: :cascade do |t|
      t.integer  "month",      limit: 2, null: false
      t.integer  "year",       limit: 2, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "monthly_statistics", ["month", "year"], name: "index_monthly_statistics_on_month_and_year", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE monthly_statistics_master (
        id integer NOT NULL default nextval('monthly_statistics_id_seq'::regclass),
        month smallint NOT NULL,
        year smallint NOT NULL,
        created_at timestamp without time zone,
        updated_at timestamp without time zone
    )  INHERITS(monthly_statistics) SERVER master_server OPTIONS(table_name 'monthly_statistics');
    SELECT setval('monthly_statistics_id_seq', COALESCE((SELECT MAX(id) FROM monthly_statistics_master) + 1, 1), false);
    SQL


    create_table "partner_rewards", force: :cascade do |t|
      t.integer  "customer_id"
      t.integer  "invited_customer_id"
      t.integer  "fee"
      t.integer  "transaction_id"
      t.datetime "created_at",          null: false
      t.datetime "updated_at",          null: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE partner_rewards_master (
        id integer NOT NULL default nextval('partner_rewards_id_seq'::regclass),
        customer_id integer,
        invited_customer_id integer,
        fee integer,
        transaction_id integer,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(partner_rewards) SERVER master_server OPTIONS(table_name 'partner_rewards');
    SELECT setval('partner_rewards_id_seq', COALESCE((SELECT MAX(id) FROM partner_rewards_master) + 1, 1), false);
    SQL


    create_table "recommender_statistics", force: :cascade do |t|
      t.string   "efficiency", limit: 3000
      t.integer  "shop_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "recommender_statistics", ["shop_id"], name: "index_recommender_statistics_on_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE recommender_statistics_master (
        id integer NOT NULL default nextval('recommender_statistics_id_seq'::regclass),
        efficiency character varying(3000),
        shop_id integer,
        created_at timestamp without time zone,
        updated_at timestamp without time zone
    )  INHERITS(recommender_statistics) SERVER master_server OPTIONS(table_name 'recommender_statistics');
    SELECT setval('recommender_statistics_id_seq', COALESCE((SELECT MAX(id) FROM recommender_statistics_master) + 1, 1), false);
    SQL


    create_table "requisites", force: :cascade do |t|
      t.integer  "requisitable_id",                   null: false
      t.string   "requisitable_type",     limit: 255, null: false
      t.text     "name",                              null: false
      t.string   "inn",                   limit: 12,  null: false
      t.string   "kpp",                   limit: 9,   null: false
      t.text     "legal_address",                     null: false
      t.text     "mailing_address",                   null: false
      t.text     "bank_name",                         null: false
      t.string   "bik",                   limit: 9,   null: false
      t.string   "correspondent_account", limit: 20,  null: false
      t.string   "checking_account",      limit: 20,  null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "requisites", ["requisitable_id", "requisitable_type"], name: "index_requisites_on_requisitable_id_and_requisitable_type", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE requisites_master (
        id integer NOT NULL default nextval('requisites_id_seq'::regclass),
        requisitable_id integer NOT NULL,
        requisitable_type character varying(255) NOT NULL,
        name text NOT NULL,
        inn character varying(12) NOT NULL,
        kpp character varying(9) NOT NULL,
        legal_address text NOT NULL,
        mailing_address text NOT NULL,
        bank_name text NOT NULL,
        bik character varying(9) NOT NULL,
        correspondent_account character varying(20) NOT NULL,
        checking_account character varying(20) NOT NULL,
        created_at timestamp without time zone,
        updated_at timestamp without time zone
    )  INHERITS(requisites) SERVER master_server OPTIONS(table_name 'requisites');
    SELECT setval('requisites_id_seq', COALESCE((SELECT MAX(id) FROM requisites_master) + 1, 1), false);
    SQL


    create_table "rewards", force: :cascade do |t|
      t.integer  "manager_id",                           null: false
      t.integer  "customer_id",                          null: false
      t.integer  "transaction_id",                       null: false
      t.integer  "financial_manager_id"
      t.boolean  "paid",                 default: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "rewards", ["manager_id"], name: "index_rewards_on_manager_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE rewards_master (
        id integer NOT NULL default nextval('rewards_id_seq'::regclass),
        manager_id integer NOT NULL,
        customer_id integer NOT NULL,
        transaction_id integer NOT NULL,
        financial_manager_id integer,
        paid boolean DEFAULT false,
        created_at timestamp without time zone,
        updated_at timestamp without time zone
    )  INHERITS(rewards) SERVER master_server OPTIONS(table_name 'rewards');
    SELECT setval('rewards_id_seq', COALESCE((SELECT MAX(id) FROM rewards_master) + 1, 1), false);
    SQL


    create_table "segments", force: :cascade do |t|
      t.integer  "shop_id",                               null: false
      t.string   "name",                                  null: false
      t.integer  "segment_type",          default: 0,     null: false
      t.integer  "client_count",          default: 0,     null: false
      t.integer  "with_email_count",      default: 0,     null: false
      t.integer  "trigger_client_count",  default: 0,     null: false
      t.integer  "digest_client_count",   default: 0,     null: false
      t.integer  "web_push_client_count", default: 0,     null: false
      t.datetime "created_at",                            null: false
      t.datetime "updated_at",                            null: false
      t.boolean  "deleted",               default: false, null: false
      t.boolean  "updating",              default: false, null: false
      t.jsonb    "filters",               default: {},    null: false
    end

    add_index "segments", ["shop_id"], name: "index_segments_on_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE segments_master (
        id integer NOT NULL default nextval('segments_id_seq'::regclass),
        shop_id integer NOT NULL,
        name character varying NOT NULL,
        segment_type integer DEFAULT 0 NOT NULL,
        client_count integer DEFAULT 0 NOT NULL,
        with_email_count integer DEFAULT 0 NOT NULL,
        trigger_client_count integer DEFAULT 0 NOT NULL,
        digest_client_count integer DEFAULT 0 NOT NULL,
        web_push_client_count integer DEFAULT 0 NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        deleted boolean DEFAULT false NOT NULL,
        updating boolean DEFAULT false NOT NULL,
        filters jsonb DEFAULT '{}'::jsonb NOT NULL
    )  INHERITS(segments) SERVER master_server OPTIONS(table_name 'segments');
    SELECT setval('segments_id_seq', COALESCE((SELECT MAX(id) FROM segments_master) + 1, 1), false);
    SQL


    create_table "shop_days_statistics", force: :cascade do |t|
      t.integer "shop_id"
      t.decimal "natural"
      t.decimal "recommended"
      t.date    "date"
      t.integer "natural_count",     default: 0
      t.integer "recommended_count", default: 0
      t.text    "orders_info"
    end

    add_index "shop_days_statistics", ["shop_id"], name: "index_shop_days_statistics_on_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE shop_days_statistics_master (
        id integer NOT NULL default nextval('shop_days_statistics_id_seq'::regclass),
        shop_id integer,
        "natural" numeric,
        recommended numeric,
        date date,
        natural_count integer DEFAULT 0,
        recommended_count integer DEFAULT 0,
        orders_info text
    )  INHERITS(shop_days_statistics) SERVER master_server OPTIONS(table_name 'shop_days_statistics');
    SELECT setval('shop_days_statistics_id_seq', COALESCE((SELECT MAX(id) FROM shop_days_statistics_master) + 1, 1), false);
    SQL


    create_table "shop_images", force: :cascade do |t|
      t.integer  "shop_id",                null: false
      t.string   "file",                   null: false
      t.datetime "created_at",             null: false
      t.datetime "updated_at",             null: false
      t.integer  "image_type", default: 0, null: false
    end
    add_index "shop_images", ["shop_id", "image_type"], name: "index_shop_images_on_shop_id_and_image_type", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE shop_images_master (
        id integer NOT NULL default nextval('shop_images_id_seq'::regclass),
        shop_id integer NOT NULL,
        file character varying NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        image_type integer DEFAULT 0 NOT NULL
    )  INHERITS(shop_images) SERVER master_server OPTIONS(table_name 'shop_images');
    SELECT setval('shop_images_id_seq', COALESCE((SELECT MAX(id) FROM shop_images_master) + 1, 1), false);
    SQL


    create_table "shop_inventories", force: :cascade do |t|
      t.integer  "shop_id"
      t.integer  "inventory_type"
      t.boolean  "active"
      t.datetime "created_at",                     null: false
      t.datetime "updated_at",                     null: false
      t.float    "min_cpc_price",  default: 1.0,   null: false
      t.integer  "currency_id",                    null: false
      t.string   "name"
      t.integer  "image_width"
      t.integer  "image_height"
      t.jsonb    "settings"
      t.boolean  "archive",        default: false, null: false
      t.integer  "payment_type",   default: 0,     null: false
    end
    add_index "shop_inventories", ["shop_id", "inventory_type"], name: "index_shop_inventories_on_shop_id_and_inventory_type", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE shop_inventories_master (
        id integer NOT NULL default nextval('shop_inventories_id_seq'::regclass),
        shop_id integer,
        inventory_type integer,
        active boolean,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        min_cpc_price double precision DEFAULT 1.0 NOT NULL,
        currency_id integer NOT NULL,
        name character varying,
        image_width integer,
        image_height integer,
        settings jsonb,
        archive boolean DEFAULT false NOT NULL,
        payment_type integer DEFAULT 0 NOT NULL
    )  INHERITS(shop_inventories) SERVER master_server OPTIONS(table_name 'shop_inventories');
    SELECT setval('shop_inventories_id_seq', COALESCE((SELECT MAX(id) FROM shop_inventories_master) + 1, 1), false);
    SQL


    create_table "shop_inventory_banners", force: :cascade do |t|
      t.integer  "shop_inventory_id",                null: false
      t.string   "image_file_name",                  null: false
      t.string   "image_content_type",               null: false
      t.integer  "image_file_size",                  null: false
      t.datetime "image_updated_at",                 null: false
      t.string   "url",                              null: false
      t.datetime "created_at",                       null: false
      t.datetime "updated_at",                       null: false
      t.float    "ratio",              default: 1.0, null: false
      t.integer  "position",           default: 1,   null: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE shop_inventory_banners_master (
        id integer NOT NULL default nextval('shop_inventory_banners_id_seq'::regclass),
        shop_inventory_id integer NOT NULL,
        image_file_name character varying NOT NULL,
        image_content_type character varying NOT NULL,
        image_file_size integer NOT NULL,
        image_updated_at timestamp without time zone NOT NULL,
        url character varying NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        ratio double precision DEFAULT 1.0 NOT NULL,
        "position" integer DEFAULT 1 NOT NULL
    )  INHERITS(shop_inventory_banners) SERVER master_server OPTIONS(table_name 'shop_inventory_banners');
    SELECT setval('shop_inventory_banners_id_seq', COALESCE((SELECT MAX(id) FROM shop_inventory_banners_master) + 1, 1), false);
    SQL


    create_table "shop_statistics", force: :cascade do |t|
      t.integer "shop_id"
      t.decimal "day_recommended"
      t.decimal "day_natural"
      t.decimal "week_recommended"
      t.decimal "week_natural"
      t.decimal "month_recommended"
      t.decimal "month_natural"
      t.integer "day_recommended_count",   default: 0
      t.integer "day_natural_count",       default: 0
      t.integer "week_recommended_count",  default: 0
      t.integer "week_natural_count",      default: 0
      t.integer "month_recommended_count", default: 0
      t.integer "month_natural_count",     default: 0
    end
    execute <<-SQL
    CREATE FOREIGN TABLE shop_statistics_master (
        id integer NOT NULL default nextval('shop_statistics_id_seq'::regclass),
        shop_id integer,
        day_recommended numeric,
        day_natural numeric,
        week_recommended numeric,
        week_natural numeric,
        month_recommended numeric,
        month_natural numeric,
        day_recommended_count integer DEFAULT 0,
        day_natural_count integer DEFAULT 0,
        week_recommended_count integer DEFAULT 0,
        week_natural_count integer DEFAULT 0,
        month_recommended_count integer DEFAULT 0,
        month_natural_count integer DEFAULT 0
    )  INHERITS(shop_statistics) SERVER master_server OPTIONS(table_name 'shop_statistics');
    SELECT setval('shop_statistics_id_seq', COALESCE((SELECT MAX(id) FROM shop_statistics_master) + 1, 1), false);
    SQL


    create_table "shopify_shops", force: :cascade do |t|
      t.integer  "shop_id"
      t.string   "token",      null: false
      t.string   "domain",     null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    add_index "shopify_shops", ["shop_id"], name: "index_shopify_shops_on_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE shopify_shops_master (
        id integer NOT NULL default nextval('shopify_shops_id_seq'::regclass),
        shop_id integer,
        token character varying NOT NULL,
        domain character varying NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(shopify_shops) SERVER master_server OPTIONS(table_name 'shopify_shops');
    SELECT setval('shopify_shops_id_seq', COALESCE((SELECT MAX(id) FROM shopify_shops_master) + 1, 1), false);
    SQL


    create_table "shops", id: :bigserial, force: :cascade do |t|
      t.string   "uniqid",                        limit: 255,                 null: false
      t.string   "name",                          limit: 255,                 null: false
      t.boolean  "active",                                    default: true,  null: false
      t.integer  "customer_id"
      t.boolean  "connected",                                 default: false
      t.string   "url",                           limit: 255
      t.boolean  "ab_testing"
      t.datetime "ab_testing_started_at"
      t.datetime "ab_testing_finished_at"
      t.string   "secret",                        limit: 255
      t.integer  "partner_id"
      t.datetime "connected_at"
      t.string   "mean_monthly_orders_count",     limit: 255
      t.integer  "category_id"
      t.integer  "cms_id"
      t.string   "currency",                      limit: 255, default: "₽"
      t.boolean  "requested_ab_testing",                      default: false, null: false
      t.string   "yml_file_url",                  limit: 255
      t.boolean  "yml_loaded",                                default: false, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "strict_recommendations",                    default: false, null: false
      t.boolean  "export_to_ct",                              default: false
      t.integer  "manager_id"
      t.boolean  "enable_nda",                                default: false
      t.boolean  "gives_rewards",                             default: true,  null: false
      t.boolean  "hopeless",                                  default: false, null: false
      t.boolean  "restricted",                                default: false, null: false
      t.datetime "last_valid_yml_file_loaded_at"
      t.text     "connection_status_last_track"
      t.string   "brb_address"
      t.integer  "shard",                                     default: 0,     null: false
      t.datetime "manager_remind_date"
      t.integer  "yml_errors",                                default: 0,     null: false
      t.boolean  "track_order_status",                        default: false, null: false
      t.integer  "trigger_pause",                             default: 1
      t.integer  "yml_load_period",                           default: 24,    null: false
      t.datetime "last_try_to_load_yml_at"
      t.boolean  "supply_available",                          default: false, null: false
      t.boolean  "use_brb",                                   default: false
      t.integer  "scoring",                                   default: 0,     null: false
      t.decimal  "triggers_cpa",                              default: 4.6,   null: false
      t.decimal  "digests_cpa",                               default: 2.0,   null: false
      t.decimal  "triggers_cpa_cap",                          default: 300.0, null: false
      t.decimal  "digests_cpa_cap",                           default: 300.0, null: false
      t.boolean  "remarketing_enabled",                       default: false
      t.decimal  "remarketing_cpa",                           default: 4.6,   null: false
      t.decimal  "remarketing_cpa_cap",                       default: 300.0, null: false
      t.boolean  "match_users_with_dmp",                      default: true
      t.integer  "web_push_balance",                          default: 100,   null: false
      t.datetime "last_orders_sync"
      t.boolean  "have_industry_products",                    default: false, null: false
      t.string   "logo_file_name"
      t.string   "logo_content_type"
      t.integer  "logo_file_size"
      t.datetime "logo_updated_at"
      t.string   "plan",                                      default: "l"
      t.boolean  "plan_fixed",                                default: false
      t.string   "currency_code"
      t.integer  "js_sdk"
      t.boolean  "reputations_enabled",                       default: false, null: false
      t.integer  "geo_law"
      t.boolean  "has_products_jewelry",                      default: false
      t.boolean  "has_products_kids",                         default: false
      t.boolean  "has_products_fashion",                      default: false
      t.boolean  "has_products_pets",                         default: false
      t.boolean  "has_products_cosmetic",                     default: false
      t.boolean  "has_products_fmcg",                         default: false
      t.boolean  "has_products_auto",                         default: false
      t.jsonb    "verify_domain",                             default: {},    null: false
      t.datetime "last_orders_import_at"
      t.datetime "yml_load_start_at"
      t.string   "yml_state"
      t.boolean  "mailings_restricted",                       default: false, null: false
      t.boolean  "yml_notification",                          default: true,  null: false
      t.boolean  "dont_disconnect",                           default: false, null: false
      t.boolean  "has_products_realty",                       default: false
    end

    add_index "shops", ["cms_id"], name: "index_shops_on_cms_id", using: :btree
    add_index "shops", ["customer_id"], name: "index_shops_on_customer_id", using: :btree
    add_index "shops", ["manager_id"], name: "index_shops_on_manager_id", using: :btree
    add_index "shops", ["uniqid"], name: "shops_uniqid_key", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE shops_master (
        id bigint NOT NULL default nextval('shops_id_seq'::regclass),
        uniqid character varying(255) NOT NULL,
        name character varying(255) NOT NULL,
        active boolean DEFAULT true NOT NULL,
        customer_id integer,
        connected boolean DEFAULT false,
        url character varying(255),
        ab_testing boolean,
        ab_testing_started_at timestamp without time zone,
        ab_testing_finished_at timestamp without time zone,
        secret character varying(255),
        partner_id integer,
        connected_at timestamp without time zone,
        mean_monthly_orders_count character varying(255),
        category_id integer,
        cms_id integer,
        currency character varying(255) DEFAULT '₽'::character varying,
        requested_ab_testing boolean DEFAULT false NOT NULL,
        yml_file_url character varying(255),
        yml_loaded boolean DEFAULT false NOT NULL,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        strict_recommendations boolean DEFAULT false NOT NULL,
        export_to_ct boolean DEFAULT false,
        manager_id integer,
        enable_nda boolean DEFAULT false,
        gives_rewards boolean DEFAULT true NOT NULL,
        hopeless boolean DEFAULT false NOT NULL,
        restricted boolean DEFAULT false NOT NULL,
        last_valid_yml_file_loaded_at timestamp without time zone,
        connection_status_last_track text,
        brb_address character varying,
        shard integer DEFAULT 0 NOT NULL,
        manager_remind_date timestamp without time zone,
        yml_errors integer DEFAULT 0 NOT NULL,
        track_order_status boolean DEFAULT false NOT NULL,
        trigger_pause integer DEFAULT 1,
        yml_load_period integer DEFAULT 24 NOT NULL,
        last_try_to_load_yml_at timestamp without time zone,
        supply_available boolean DEFAULT false NOT NULL,
        use_brb boolean DEFAULT false,
        scoring integer DEFAULT 0 NOT NULL,
        triggers_cpa numeric DEFAULT 4.6 NOT NULL,
        digests_cpa numeric DEFAULT 2.0 NOT NULL,
        triggers_cpa_cap numeric DEFAULT 300 NOT NULL,
        digests_cpa_cap numeric DEFAULT 300 NOT NULL,
        remarketing_enabled boolean DEFAULT false,
        remarketing_cpa numeric DEFAULT 4.6 NOT NULL,
        remarketing_cpa_cap numeric DEFAULT 300 NOT NULL,
        match_users_with_dmp boolean DEFAULT true,
        web_push_balance integer DEFAULT 100 NOT NULL,
        last_orders_sync timestamp without time zone,
        have_industry_products boolean DEFAULT false NOT NULL,
        logo_file_name character varying,
        logo_content_type character varying,
        logo_file_size integer,
        logo_updated_at timestamp without time zone,
        plan character varying DEFAULT 'l'::character varying,
        plan_fixed boolean DEFAULT false,
        currency_code character varying,
        js_sdk integer,
        reputations_enabled boolean DEFAULT false NOT NULL,
        geo_law integer,
        has_products_jewelry boolean DEFAULT false,
        has_products_kids boolean DEFAULT false,
        has_products_fashion boolean DEFAULT false,
        has_products_pets boolean DEFAULT false,
        has_products_cosmetic boolean DEFAULT false,
        has_products_fmcg boolean DEFAULT false,
        has_products_auto boolean DEFAULT false,
        verify_domain jsonb DEFAULT '{}'::jsonb NOT NULL,
        last_orders_import_at timestamp without time zone,
        yml_load_start_at timestamp without time zone,
        yml_state character varying,
        mailings_restricted boolean DEFAULT false NOT NULL,
        yml_notification boolean DEFAULT true NOT NULL,
        dont_disconnect boolean DEFAULT false NOT NULL,
        has_products_realty boolean DEFAULT false
    )  INHERITS(shops) SERVER master_server OPTIONS(table_name 'shops');
    SELECT setval('shops_id_seq', COALESCE((SELECT MAX(id) FROM shops_master) + 1, 1), false);
    SQL


    create_table "styles", force: :cascade do |t|
      t.integer  "shop_id",                 null: false
      t.string   "shop_uniqid", limit: 255, null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "theme_id",    limit: 8
      t.string   "theme_type"
    end

    add_index "styles", ["shop_id", "theme_id", "theme_type"], name: "index_styles_theme", using: :btree
    add_index "styles", ["shop_id"], name: "index_styles_on_shop_id", unique: true, using: :btree
    add_index "styles", ["shop_uniqid"], name: "index_styles_on_shop_uniqid", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE styles_master (
        id integer NOT NULL default nextval('styles_id_seq'::regclass),
        shop_id integer NOT NULL,
        shop_uniqid character varying(255) NOT NULL,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        theme_id bigint,
        theme_type character varying
    )  INHERITS(styles) SERVER master_server OPTIONS(table_name 'styles');
    SELECT setval('styles_id_seq', COALESCE((SELECT MAX(id) FROM styles_master) + 1, 1), false);
    SQL


    create_table "subscription_invoices", force: :cascade do |t|
      t.integer  "shop_id"
      t.date     "date"
      t.float    "amount"
      t.integer  "subscription_plan_id"
      t.datetime "created_at",           null: false
      t.datetime "updated_at",           null: false
    end

    add_index "subscription_invoices", ["shop_id"], name: "index_subscription_invoices_on_shop_id", using: :btree
    add_index "subscription_invoices", ["subscription_plan_id"], name: "index_subscription_invoices_on_subscription_plan_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE subscription_invoices_master (
        id integer NOT NULL default nextval('subscription_invoices_id_seq'::regclass),
        shop_id integer,
        date date,
        amount double precision,
        subscription_plan_id integer,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(subscription_invoices) SERVER master_server OPTIONS(table_name 'subscription_invoices');
    SELECT setval('subscription_invoices_id_seq', COALESCE((SELECT MAX(id) FROM subscription_invoices_master) + 1, 1), false);
    SQL


    create_table "subscription_plans", force: :cascade do |t|
      t.integer  "shop_id"
      t.datetime "paid_till"
      t.decimal  "price"
      t.string   "product"
      t.datetime "created_at",                null: false
      t.datetime "updated_at",                null: false
      t.boolean  "active",     default: true
      t.boolean  "renewal",    default: true, null: false
    end

    add_index "subscription_plans", ["shop_id"], name: "index_subscription_plans_on_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE subscription_plans_master (
        id integer NOT NULL default nextval('subscription_plans_id_seq'::regclass),
        shop_id integer,
        paid_till timestamp without time zone,
        price numeric,
        product character varying,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        active boolean DEFAULT true,
        renewal boolean DEFAULT true NOT NULL
    )  INHERITS(subscription_plans) SERVER master_server OPTIONS(table_name 'subscription_plans');
    SELECT setval('subscription_plans_id_seq', COALESCE((SELECT MAX(id) FROM subscription_plans_master) + 1, 1), false);
    SQL


    create_table "theme_purchases", force: :cascade do |t|
      t.integer  "theme_id"
      t.integer  "shop_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    add_index "theme_purchases", ["shop_id"], name: "index_theme_purchases_on_shop_id", using: :btree
    add_index "theme_purchases", ["theme_id", "shop_id"], name: "index_theme_purchases_on_theme_id_and_shop_id", unique: true, using: :btree
    add_index "theme_purchases", ["theme_id"], name: "index_theme_purchases_on_theme_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE theme_purchases_master (
        id integer NOT NULL default nextval('theme_purchases_id_seq'::regclass),
        theme_id integer,
        shop_id integer,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(theme_purchases) SERVER master_server OPTIONS(table_name 'theme_purchases');
    SELECT setval('theme_purchases_id_seq', COALESCE((SELECT MAX(id) FROM theme_purchases_master) + 1, 1), false);
    SQL


    create_table "themes", force: :cascade do |t|
      t.string   "name",                       null: false
      t.string   "theme_type",                 null: false
      t.jsonb    "variables"
      t.string   "file",                       null: false
      t.boolean  "free",       default: false, null: false
      t.datetime "created_at",                 null: false
      t.datetime "updated_at",                 null: false
    end

    add_index "themes", ["name", "theme_type"], name: "index_themes_on_name_and_theme_type", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE themes_master (
        id integer NOT NULL default nextval('themes_id_seq'::regclass),
        name character varying NOT NULL,
        theme_type character varying NOT NULL,
        variables jsonb,
        file character varying NOT NULL,
        free boolean DEFAULT false NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(themes) SERVER master_server OPTIONS(table_name 'themes');
    SELECT setval('themes_id_seq', COALESCE((SELECT MAX(id) FROM themes_master) + 1, 1), false);
    SQL


    create_table "transactions", force: :cascade do |t|
      t.integer  "amount",                       default: 500, null: false
      t.integer  "transaction_type",             default: 0,   null: false
      t.string   "payment_method",   limit: 255,               null: false
      t.integer  "status",                       default: 0
      t.integer  "customer_id"
      t.datetime "processed_at"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "comment"
      t.integer  "shop_id"
      t.integer  "currency_id",                  default: 1,   null: false
      t.string   "transaction_id"
    end
    execute <<-SQL
    CREATE FOREIGN TABLE transactions_master (
        id integer NOT NULL default nextval('transactions_id_seq'::regclass),
        amount integer DEFAULT 500 NOT NULL,
        transaction_type integer DEFAULT 0 NOT NULL,
        payment_method character varying(255) NOT NULL,
        status integer DEFAULT 0,
        customer_id integer,
        processed_at timestamp without time zone,
        created_at timestamp without time zone,
        updated_at timestamp without time zone,
        comment text,
        shop_id integer,
        currency_id integer DEFAULT 1 NOT NULL,
        transaction_id character varying
    )  INHERITS(transactions) SERVER master_server OPTIONS(table_name 'transactions');
    SELECT setval('transactions_id_seq', COALESCE((SELECT MAX(id) FROM transactions_master) + 1, 1), false);
    SQL


    create_table "trigger_mail_statistics", force: :cascade do |t|
      t.date     "date",                   null: false
      t.integer  "shop_id",                null: false
      t.integer  "opened",     default: 0, null: false
      t.integer  "clicked",    default: 0, null: false
      t.integer  "bounced",    default: 0, null: false
      t.integer  "sent",       default: 0, null: false
      t.datetime "created_at",             null: false
      t.datetime "updated_at",             null: false
    end

    add_index "trigger_mail_statistics", ["date"], name: "index_trigger_mail_statistics_on_date", using: :btree
    add_index "trigger_mail_statistics", ["shop_id", "date"], name: "index_trigger_mail_statistics_on_shop_id_and_date", unique: true, using: :btree
    add_index "trigger_mail_statistics", ["shop_id"], name: "index_trigger_mail_statistics_on_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE trigger_mail_statistics_master (
        id integer NOT NULL default nextval('trigger_mail_statistics_id_seq'::regclass),
        date date NOT NULL,
        shop_id integer NOT NULL,
        opened integer DEFAULT 0 NOT NULL,
        clicked integer DEFAULT 0 NOT NULL,
        bounced integer DEFAULT 0 NOT NULL,
        sent integer DEFAULT 0 NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(trigger_mail_statistics) SERVER master_server OPTIONS(table_name 'trigger_mail_statistics');
    SELECT setval('trigger_mail_statistics_id_seq', COALESCE((SELECT MAX(id) FROM trigger_mail_statistics_master) + 1, 1), false);
    SQL


    create_table "user_taxonomies", force: :cascade do |t|
      t.integer "user_id"
      t.date    "date"
      t.string  "taxonomy"
      t.string  "brand"
      t.string  "event"
    end

    add_index "user_taxonomies", ["date"], name: "index_user_taxonomies_on_date", using: :btree
    add_index "user_taxonomies", ["taxonomy"], name: "index_user_taxonomies_on_taxonomy", using: :btree
    add_index "user_taxonomies", ["user_id", "taxonomy", "date", "brand"], name: "index_user_taxonomies_with_brand", using: :btree
    add_index "user_taxonomies", ["user_id", "taxonomy", "date"], name: "index_user_taxonomies_on_user_id_and_taxonomy_and_date", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE user_taxonomies_master (
        id integer NOT NULL default nextval('user_taxonomies_id_seq'::regclass),
        user_id integer,
        date date,
        taxonomy character varying,
        brand character varying,
        event character varying
    )  INHERITS(user_taxonomies) SERVER master_server OPTIONS(table_name 'user_taxonomies');
    SELECT setval('user_taxonomies_id_seq', COALESCE((SELECT MAX(id) FROM user_taxonomies_master) + 1, 1), false);
    SQL


    create_table "vendor_campaigns", force: :cascade do |t|
      t.integer  "vendor_id"
      t.integer  "shop_id"
      t.string   "name"
      t.datetime "created_at",                     null: false
      t.datetime "updated_at",                     null: false
      t.integer  "shop_inventory_id",              null: false
      t.float    "max_cpc_price",                  null: false
      t.integer  "currency_id",                    null: false
      t.datetime "launched_at"
      t.integer  "status",             default: 0
      t.string   "brand"
      t.string   "image_file_name"
      t.string   "image_content_type"
      t.integer  "image_file_size"
      t.datetime "image_updated_at"
      t.string   "url"
      t.string   "categories",                                  array: true
      t.boolean  "all_categories"
      t.integer  "item_count"
    end

    add_index "vendor_campaigns", ["vendor_id", "shop_id"], name: "index_vendor_campaigns_on_vendor_id_and_shop_id", using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE vendor_campaigns_master (
        id integer NOT NULL default nextval('vendor_campaigns_id_seq'::regclass),
        vendor_id integer,
        shop_id integer,
        name character varying,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        shop_inventory_id integer NOT NULL,
        max_cpc_price double precision NOT NULL,
        currency_id integer NOT NULL,
        launched_at timestamp without time zone,
        status integer DEFAULT 0,
        brand character varying,
        image_file_name character varying,
        image_content_type character varying,
        image_file_size integer,
        image_updated_at timestamp without time zone,
        url character varying,
        categories character varying[],
        all_categories boolean,
        item_count integer,
        filters jsonb DEFAULT '{}'::jsonb NOT NULL
    )  INHERITS(vendor_campaigns) SERVER master_server OPTIONS(table_name 'vendor_campaigns');
    SELECT setval('vendor_campaigns_id_seq', COALESCE((SELECT MAX(id) FROM vendor_campaigns_master) + 1, 1), false);
    SQL


    create_table "vendor_shops", force: :cascade do |t|
      t.integer  "shop_id"
      t.integer  "vendor_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    add_index "vendor_shops", ["vendor_id", "shop_id"], name: "index_vendor_shops_on_vendor_id_and_shop_id", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE vendor_shops_master (
        id integer NOT NULL default nextval('vendor_shops_id_seq'::regclass),
        shop_id integer,
        vendor_id integer,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(vendor_shops) SERVER master_server OPTIONS(table_name 'vendor_shops');
    SELECT setval('vendor_shops_id_seq', COALESCE((SELECT MAX(id) FROM vendor_shops_master) + 1, 1), false);
    SQL


    create_table "vendors", force: :cascade do |t|
      t.string   "name"
      t.string   "url"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE vendors_master (
        id integer NOT NULL default nextval('vendors_id_seq'::regclass),
        name character varying,
        url character varying,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(vendors) SERVER master_server OPTIONS(table_name 'vendors');
    SELECT setval('vendors_id_seq', COALESCE((SELECT MAX(id) FROM vendors_master) + 1, 1), false);
    SQL


    create_table "wear_type_dictionaries", force: :cascade do |t|
      t.string "type_name"
      t.string "word"
    end
    execute <<-SQL
    CREATE FOREIGN TABLE wear_type_dictionaries_master (
        id integer NOT NULL default nextval('wear_type_dictionaries_id_seq'::regclass),
        type_name character varying,
        word character varying
    )  INHERITS(wear_type_dictionaries) SERVER master_server OPTIONS(table_name 'wear_type_dictionaries');
    SELECT setval('wear_type_dictionaries_id_seq', COALESCE((SELECT MAX(id) FROM wear_type_dictionaries_master) + 1, 1), false);
    SQL


    create_table "web_push_packet_purchases", force: :cascade do |t|
      t.integer  "customer_id"
      t.integer  "shop_id"
      t.integer  "amount",      null: false
      t.integer  "price",       null: false
      t.integer  "currency_id", null: false
      t.datetime "created_at",  null: false
      t.datetime "updated_at",  null: false
    end
    execute <<-SQL
    CREATE FOREIGN TABLE web_push_packet_purchases_master (
        id integer NOT NULL default nextval('web_push_packet_purchases_id_seq'::regclass),
        customer_id integer,
        shop_id integer,
        amount integer NOT NULL,
        price integer NOT NULL,
        currency_id integer NOT NULL,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL
    )  INHERITS(web_push_packet_purchases) SERVER master_server OPTIONS(table_name 'web_push_packet_purchases');
    SELECT setval('web_push_packet_purchases_id_seq', COALESCE((SELECT MAX(id) FROM web_push_packet_purchases_master) + 1, 1), false);
    SQL


    create_table "wizard_configurations", force: :cascade do |t|
      t.integer  "shop_id",                           null: false
      t.jsonb    "industrials",       default: []
      t.boolean  "orders_history",    default: false
      t.boolean  "orders_sync",       default: false
      t.jsonb    "triggers",          default: []
      t.jsonb    "web_push_triggers", default: []
      t.boolean  "completed",         default: false
      t.datetime "created_at",                        null: false
      t.datetime "updated_at",                        null: false
      t.integer  "locations",         default: 0
      t.boolean  "subscribers",       default: false
      t.jsonb    "products",          default: []
    end

    add_index "wizard_configurations", ["shop_id"], name: "index_wizard_configurations_on_shop_id", unique: true, using: :btree
    execute <<-SQL
    CREATE FOREIGN TABLE wizard_configurations_master (
        id integer NOT NULL default nextval('wizard_configurations_id_seq'::regclass),
        shop_id integer NOT NULL,
        industrials jsonb DEFAULT '[]'::jsonb,
        orders_history boolean DEFAULT false,
        orders_sync boolean DEFAULT false,
        triggers jsonb DEFAULT '[]'::jsonb,
        web_push_triggers jsonb DEFAULT '[]'::jsonb,
        completed boolean DEFAULT false,
        created_at timestamp without time zone NOT NULL,
        updated_at timestamp without time zone NOT NULL,
        locations integer DEFAULT 0,
        products jsonb DEFAULT '[]'::jsonb,
        subscribers boolean DEFAULT false
    )  INHERITS(wizard_configurations) SERVER master_server OPTIONS(table_name 'wizard_configurations');
    SELECT setval('wizard_configurations_id_seq', COALESCE((SELECT MAX(id) FROM wizard_configurations_master) + 1, 1), false);
    SQL

  end

  def down
    config = ActiveRecord::Base.configurations["#{Rails.env}"]

    execute <<-SQL
      DROP TABLE active_admin_comments CASCADE;
      DROP TABLE advertiser_vendors CASCADE;
      DROP TABLE advertisers CASCADE;
      DROP TABLE ar_internal_metadata CASCADE;
      DROP TABLE brand_campaign_item_categories CASCADE;
      DROP TABLE brand_campaign_purchases CASCADE;
      DROP TABLE brand_campaigns CASCADE;
      DROP TABLE brands CASCADE;
      DROP TABLE categories CASCADE;
      DROP TABLE cmses CASCADE;
      DROP TABLE cpa_invoices CASCADE;
      DROP TABLE currencies CASCADE;
      DROP TABLE customer_balance_histories CASCADE;
      DROP TABLE customers CASCADE;
      DROP TABLE digest_mail_statistics CASCADE;
      DROP TABLE employees CASCADE;
      DROP TABLE industries CASCADE;
      DROP TABLE insales_shops CASCADE;
      DROP TABLE instant_auth_tokens CASCADE;
      DROP TABLE invalid_emails CASCADE;
      DROP TABLE ipn_messages CASCADE;
      DROP TABLE leads CASCADE;
      DROP TABLE mail_ru_audience_pools CASCADE;
      DROP TABLE monthly_statistic_items CASCADE;
      DROP TABLE monthly_statistics CASCADE;
      DROP TABLE partner_rewards CASCADE;
      DROP TABLE recommender_statistics CASCADE;
      DROP TABLE requisites CASCADE;
      DROP TABLE rewards CASCADE;
      DROP TABLE segments CASCADE;
      DROP TABLE shop_days_statistics CASCADE;
      DROP TABLE shop_images CASCADE;
      DROP TABLE shop_inventories CASCADE;
      DROP TABLE shop_inventory_banners CASCADE;
      DROP TABLE shop_statistics CASCADE;
      DROP TABLE shopify_shops CASCADE;
      DROP TABLE shops CASCADE;
      DROP TABLE styles CASCADE;
      DROP TABLE subscription_invoices CASCADE;
      DROP TABLE subscription_plans CASCADE;
      DROP TABLE theme_purchases CASCADE;
      DROP TABLE themes CASCADE;
      DROP TABLE transactions CASCADE;
      DROP TABLE trigger_mail_statistics CASCADE;
      DROP TABLE user_taxonomies CASCADE;
      DROP TABLE vendor_campaigns CASCADE;
      DROP TABLE vendor_shops CASCADE;
      DROP TABLE vendors CASCADE;
      DROP TABLE wear_type_dictionaries CASCADE;
      DROP TABLE web_push_packet_purchases CASCADE;
      DROP TABLE wizard_configurations CASCADE;
    SQL
  end
end
