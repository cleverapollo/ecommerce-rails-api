module UserLinkable
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    validates :user, presence: true
  end

  module ClassMethods
    def relink_user(options = {})
      where(user_id: options.fetch(:from).id).find_each do |entity|
        begin
          entity.update_columns(user_id: options.fetch(:to).id)
        rescue ActiveRecord::RecordNotUnique
          entity.delete
        end
      end
    end
  end
end