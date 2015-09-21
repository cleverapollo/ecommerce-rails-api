class AddIndexOnClients < ActiveRecord::Migration
  def change
    add_index "trigger_mails", ["shop_id", "trigger_mailing_id"], name: :index_trigger_mails_on_shop_id_and_trigger_mailing_id, where: "opened = 'f'"
  end
end
