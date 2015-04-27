##
# Аттрибут профиля пользователя
#
class ProfileAttribute < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user

  validates :user_id, presence: true
  validates :shop_id, presence: true
  validates :value, presence: true
end
