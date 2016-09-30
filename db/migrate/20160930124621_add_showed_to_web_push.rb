class AddShowedToWebPush < ActiveRecord::Migration
  def change
    add_column :web_push_digest_messages, :showed, :boolean, null: false, default: false
    add_column :web_push_trigger_messages, :showed, :boolean, null: false, default: false

    add_index :web_push_digest_messages, [:shop_id, :web_push_digest_id], where: '(showed is true)', name: :index_web_push_digest_msg_on_shop_id_and_digest_id_and_showed
    add_index :web_push_trigger_messages, [:shop_id, :web_push_trigger_id], where: '(showed is true)', name: :index_web_push_trigger_msg_on_shop_id_and_trigger_id_and_showed
  end
end
