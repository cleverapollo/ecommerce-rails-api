##
# "Действие". Связка пользователь-товар.
# Конкретные действия наследуются от этого класса
#
class Action < ActiveRecord::Base

  belongs_to :user
  belongs_to :item
  belongs_to :shop

  TYPES = Dir.glob(Rails.root + 'app/models/actions/*').map{|a| a.split('/').last.split('.').first }

  scope :by_average_rating, -> { order('AVG(rating) DESC') }

  scope :views, -> { where('rating::numeric = ?', Actions::View::RATING) }
  scope :carts, -> { where('rating::numeric = ?', Actions::Cart::RATING) }

  validates :shop_id, :user_id, :item_id, presence: true

  class << self

    # Переносит данные от одного пользователя к другому при склеивании пользователей
    # @param options [Hash] {from: [User], to: [User]}
    def relink_user(options = {})
      # @type master [User]
      master = options.fetch(:to)
      # @type slave [User]
      slave = options.fetch(:from)

      slave.actions.each do |slave_action|
        slave_action.merge_to(master)
      end
    end

    # Перелинкует всех удаленных пользователей. Такое может произойти,
    # если были одновременно отправлены данные юзера в push_attributes и создан заказ.
    # @param [User] master
    # @param [Integer] slave_id
    def relink_user_remnants(master, slave_id)
      where(user_id: slave_id).each do |slave_action|
        slave_action.merge_to(master)
      end
    end

    # Вернуть класс конкретного действия по названию
    def get_implementation_for(action_type)
      raise ActionPush::Error.new('Unsupported action type') unless TYPES.include?(action_type)

      action_implementation_class_name(action_type).constantize
    end

    # Callback
    def mass_process(params)
    end

    private

    def action_implementation_class_name(type)
      'Actions::' + type.camelize
    end
  end




  # Точка входа при обработке события. Вся работа происходит здесь.
  def process(params)
    # Обновить параметры, специфичные для конкретного класса действий
    update_concrete_action_attrs
    # Обновляем рейтинг и последнее действие - если нужно делать
    # Пример: после просмотра товар добавляют в коризну - рейтинг обновляется
    # После покупки товар смотрят - рейтинг не меняется
    update_rating_and_last_action(params.rating) if needs_to_update_rating?
    # Запоминаем код рекомендера
    set_recommended_by(params.recommended_by) if params.recommended_by.present?

    begin
      # В Махаут сохраняются действия с рейтингом больше корзины
      save_to_mahout if self.rating >= Actions::RemoveFromCart::RATING

      save
      # Коллбек после обработки действия
      post_process
    rescue ActiveRecord::RecordNotUnique => e
      # Action already saved
    end
  end

  # Перенос объекта к указанному юзеру
  # @param [User] user
  def merge_to(user)

    # @type master_action [Action]
    master_action = Action.where(shop_id: self.shop_id, user_id: user.id, item_id: self.item_id).where.not(id: self.id).order(:id).limit(1)[0]

    if master_action.present?
      master_action.update(
        view_count: master_action.view_count + self.view_count,
        cart_count: master_action.cart_count + self.cart_count,
        purchase_count: master_action.purchase_count + self.purchase_count,
        view_date: [master_action.view_date, self.view_date].compact.max,
        cart_date: [master_action.cart_date, self.cart_date].compact.max,
        purchase_date: [master_action.purchase_date, self.purchase_date].compact.max,
        rating: [master_action.rating, self.rating].compact.max,
        timestamp: [master_action.timestamp, self.timestamp].compact.max,
        recommended_by: master_action.recommended_by.present? ? master_action.recommended_by : self.recommended_by,
        recommended_at: master_action.recommended_at.present? ? master_action.recommended_at : self.recommended_at
      )

      self.delete
    else
      self.update_columns(user_id: user.id)
    end
  end

  def name_code
    self.class.to_s.split(':').last.underscore
  end

  # Callback
  def post_process
  end

  def update_concrete_action_attrs
    raise NotImplementedError.new('This method should be called on concrete action type class')
  end

  def update_rating_and_last_action(rating)
    raise NotImplementedError.new('This method should be called on concrete action type class')
  end

  def needs_to_update_rating?
    raise NotImplementedError.new('This method should be called on concrete action type class')
  end

  def set_recommended_by(recommended_by)
    self.recommended_by = recommended_by
    self.recommended_at = Time.current
  end

  def save_to_mahout
    if shop && shop.use_brb? && user && item
      mahout_service = MahoutService.new(shop.brb_address)
      mahout_service.set_preference(shop.id, user.id, item.id, self.rating)
    end
  end


  def recalculate_purchase_count_and_date!
    update_columns(
      purchase_count: OrderItem.joins(:order).where(item_id: item_id, orders: { shop_id: shop_id, user_id: user_id }).count,
      purchase_date: Order.joins(:order_items).where(shop_id: shop_id, user_id: user_id, order_items: { item_id: item_id }).order(date: :desc).limit(1).pluck(:date)[0]
    )
  end
end
