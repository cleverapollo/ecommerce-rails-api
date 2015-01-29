class MahoutAction < ActiveRecord::Base
  include UserLinkable

  before_create :assign_timestamp

  belongs_to :item
  belongs_to :shop

  protected
    def assign_timestamp
      self.timestamp = Time.current.to_i
    end
end
