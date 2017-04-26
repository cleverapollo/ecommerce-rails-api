class WebPushTokenError < ActiveRecord::Base
  belongs_to :client
  belongs_to :shop

  serialize :message, HashSerializer
end
