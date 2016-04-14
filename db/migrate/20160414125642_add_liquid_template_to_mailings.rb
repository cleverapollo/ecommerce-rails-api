class AddLiquidTemplateToMailings < ActiveRecord::Migration
  def change
    add_column :trigger_mailings, :liquid_template, :text
    add_column :digest_mailings, :liquid_template, :text
  end
end
