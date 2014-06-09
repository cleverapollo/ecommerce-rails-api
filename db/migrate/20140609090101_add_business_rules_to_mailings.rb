class AddBusinessRulesToMailings < ActiveRecord::Migration
  def change
    add_column :mailings, :business_rules, :text
  end
end
