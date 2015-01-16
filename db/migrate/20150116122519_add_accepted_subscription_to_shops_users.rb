class AddAcceptedSubscriptionToShopsUsers < ActiveRecord::Migration
  def change
    add_column :shops_users, :accepted_subscription, :boolean, null: false, default: false

    ShopsUser.who_saw_subscription_popup.with_email.update_all(accepted_subscription: true)
  end
end
