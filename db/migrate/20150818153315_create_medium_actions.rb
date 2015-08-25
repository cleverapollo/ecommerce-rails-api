class CreateMediumActions < ActiveRecord::Migration
  def change
    create_table    :medium_actions do |t|
      t.references  :medium
      t.references  :user
      t.references  :article
      t.string      :medium_action_type,     null: false
      t.string      :recommended_by

      t.timestamps
    end
  end
end
