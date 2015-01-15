##
# Аудитория дайджестных рассылок.
#
class Audience < ActiveRecord::Base
  validates_presence_of :shop_id, :external_id, :email
  serialize :custom_attributes, JSON

  belongs_to :shop
  belongs_to :user
end
