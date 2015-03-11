class CreatePromotions < ActiveRecord::Migration
  def change
    create_table :promotions do |t|
      t.string :brand, null: false
      t.string :categories, array: true, null: false

      t.timestamps null: false
    end

    Promotion.create!(brand: 'neoline', categories: ['видеорегистратор', 'радар', 'авторегистратор'])
  end
end
