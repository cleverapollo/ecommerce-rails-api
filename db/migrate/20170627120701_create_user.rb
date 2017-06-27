class CreateUser < ActiveRecord::Migration
  def change
    create_table "users", id: :bigserial, force: :cascade do |t|
      t.string  "gender",           limit: 1
      t.jsonb   "fashion_sizes"
      t.boolean "allergy"
      t.jsonb   "cosmetic_hair"
      t.jsonb   "cosmetic_skin"
      t.jsonb   "children"
      t.jsonb   "compatibility"
      t.jsonb   "vds"
      t.jsonb   "pets"
      t.jsonb   "jewelry"
      t.jsonb   "cosmetic_perfume"
    end
  end
end
