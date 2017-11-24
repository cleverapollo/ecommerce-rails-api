class ThemePurchase < ActiveRecord::Base
  belongs_to :theme
  belongs_to :shop
end
