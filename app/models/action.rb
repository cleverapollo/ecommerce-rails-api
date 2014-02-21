class Action < ActiveRecord::Base
  EVENT_TYPES = %w(view cart remove_from_cart purchase rate)
end
