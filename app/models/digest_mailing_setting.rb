##
# Настройки дайджестных рассылок.
#
class DigestMailingSetting < ActiveRecord::Base
  belongs_to :shop
end
