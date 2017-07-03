##
# Привязка к пользователю.
#
module UserLinkable
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    validates :user_id, presence: true
  end

  module ClassMethods
    # Привязать сущность к новому пользователю
    def relink_user(options = {})
      where(user_id: options.fetch(:from).id).each do |entity|
        begin
          entity.user_id = options.fetch(:to).id
          entity.atomic_save!
        rescue ActiveRecord::RecordNotUnique
          entity.delete
        end
      end
    end

    # Перелинкует всех удаленных пользователей. Такое может произойти,
    # если были одновременно отправлены данные юзера в push_attributes и создан заказ.
    # @param [User] master
    # @param [Integer] slave_id
    def relink_user_remnants(master, slave_id)
      where(user_id: slave_id).each do |entity|
        begin
          entity.user_id = master.id
          entity.atomic_save!
        rescue ActiveRecord::RecordNotUnique
          entity.delete
        end
      end
    end
  end
end
