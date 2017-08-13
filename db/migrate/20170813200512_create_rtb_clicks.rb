class CreateRtbClicks < ActiveRecord::Migration
  def change
    create_table :rtb_clicks do |t|
      t.string :url
      t.string :user_agent
      t.string :ip
      t.timestamps null: false
    end
  end
end
