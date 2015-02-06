class MahoutAction < ActiveRecord::Base
  before_create :assign_timestamp

  belongs_to :item
  belongs_to :shop
  belongs_to :user


  class << self
    def relink_user(options = {})
      where(user_id: options.fetch(:from).id).find_each do |m_a|
        if MahoutAction.where(item_id: m_a.item_id, user_id: options.fetch(:to).id).limit(1).blank?
          m_a.update_columns(user_id: options.fetch(:to).id)
        else
          m_a.delete
        end
      end
    end
  end

  protected
    def assign_timestamp
      self.timestamp = Time.current.to_i
    end
end
