class CreateSession < ActiveRecord::Migration
  def change
    create_table "sessions", id: :bigserial, force: :cascade do |t|
      t.integer "user_id",                         limit: 8,   null: false
      t.string  "code",                            limit: 255, null: false
      t.string  "city",                            limit: 255
      t.string  "country",                         limit: 255
      t.string  "language",                        limit: 255
      t.date    "synced_with_amber_at"
      t.date    "synced_with_dca_at"
      t.date    "synced_with_aidata_at"
      t.date    "synced_with_auditorius_at"
      t.date    "synced_with_mailru_at"
      t.date    "synced_with_relapio_at"
      t.date    "synced_with_republer_at"
      t.date    "synced_with_advmaker_at"
      t.string  "useragent"
      t.jsonb   "segment"
      t.date    "updated_at"
      t.date    "synced_with_doubleclick_at"
      t.date    "synced_with_doubleclick_cart_at"
    end

    add_index "sessions", ["code"], name: "sessions_uniqid_key", unique: true, using: :btree
    add_index "sessions", ["segment"], name: "index_sessions_on_segment", where: "(segment IS NOT NULL)", using: :gin
    add_index "sessions", ["user_id"], name: "index_sessions_on_user_id", using: :btree
  end
end
