class AddLanguageToSearchSetting < ActiveRecord::Migration
  def change
    add_column :search_settings, :language, :string, default: 'english'
  end
end
