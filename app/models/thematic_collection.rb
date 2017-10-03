class ThematicCollection < ActiveRecord::Base
  validates :name, presence: true
end
