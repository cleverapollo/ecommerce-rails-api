class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string      :external_id,  null: false
      t.text        :url
      t.references  :medium
      t.string      :title,        limit: 5000
      t.text        :image
      t.text        :description
      t.string      :encoding

      t.timestamps
    end
  end
end
