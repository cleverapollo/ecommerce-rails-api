class ChangeDigestToTheme < ActiveRecord::Migration
  def change
    add_column :digest_mailings, :theme_id, :integer, limit: 8
    add_column :digest_mailings, :theme_type, :string
    add_column :digest_mailings, :template_data, :jsonb
    add_column :digest_mailings, :intro_text, :string
    add_index :digest_mailings, [:shop_id, :theme_id, :theme_type], name: 'index_digest_mailings_theme'
  end
end
