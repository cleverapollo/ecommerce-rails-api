class TriggerMailingQueue < ActiveRecord::Base
  validates :shop_id, :user_id, :trigger_type, :recommended_items, :triggered_at, :email, :trigger_mail_code, presence: true
end
