class AddPlanByMails < ActiveRecord::Migration
  def change
    add_column :shops, :plan_by_mails, :boolean
    add_column :shops, :plan_by_mails_min, :integer, default: 0
    add_column :shops, :plan_by_mails_count, :integer, default: 0
    add_column :shops, :plan_by_mails_extra, :integer, default: 0
  end
end
