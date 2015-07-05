##
# Настройки дайджестных рассылок.
#
class DigestMailingSetting < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  belongs_to :shop
end
