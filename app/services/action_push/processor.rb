##
# Обработчик поступающих событий
#
module ActionPush
  class Processor
    attr_reader :params
    attr_reader :concrete_action_class

    def initialize(params)
      @params = params
      @concrete_action_class = Action.get_implementation_for params.action
    end




    # Обрабатывает действие, запоминает источники и т.д.
    # Основная точка входа.
    def process

      # Обработка триггерных писем
      if params.trigger_mail_code.present? && params.trigger_mail_code != 'test' && trigger_mail = TriggerMail.find_by(code: params.trigger_mail_code)
        trigger_mail.mark_as_clicked!
      end

      # Обработка дайджестных писем
      if params.digest_mail_code.present? && params.digest_mail_code != 'test' && digest_mail = DigestMail.find_by(code: params.digest_mail_code)
        digest_mail.mark_as_clicked!
      end

      # Обработка RTB-заказов
      if params.action.to_sym == :purchase && params.r46_returner_code.present? && params.r46_returner_code != 'test' && rtb_impression = RtbImpression.find_by(code: params.r46_returner_code)
        rtb_impression.mark_as_purchased!
      end

      # Для каждого переданного товара запускаем процессинг действия
      params.items.each do |item|

        # Находим действие по отношению к товару.
        action = fetch_action_for item

        # Запускаем обработку действия
        action.process params

        # Логгируем событие
        Interaction.push(user_id: params.user.id, shop_id: params.shop.id, item_id: item.id, type: action.name_code, recommended_by: params.recommended_by)

      end

      # Это используется в покупках
      concrete_action_class.mass_process(params)

      # Корректируем характеристики профиля покупателя для отраслевых товаров
      ProfileEvent.track_items params.user, params.shop, params.action, params.items

      # Сообщаем, что от магазина пришло событие
      params.shop.report_event(params.action.to_sym)

      # Отмечаем, что пользователь был активен
      Client.find_by(user_id: params.user.id, shop_id: params.shop.id).try(&:track_last_activity)

      # Сообщаем брокеру брошенных корзин RTB
      case params.action.to_sym
        when :cart
          Rtb::Broker.new(params.shop).notify(params.user, params.items)
        when :purchase
          Rtb::Broker.new(params.shop).clear(params.user)
        when :remove_from_cart
          Rtb::Broker.new(params.shop).clear(params.user, params.items)
      end

      # Трекаем таксономию в DMP
      UserTaxonomy.track params.user, params.items, params.shop, params.action

    end





    # Находит или создает действие пользователя по отношению к товару.
    # @param item [Item] Объект товара
    # @return Action
    def fetch_action_for(item)
      a = concrete_action_class.find_or_initialize_by(user_id: params.user.id, shop_id: params.shop.id, item_id: item.id)
      a.assign_attributes(timestamp: (params.date || Date.current.to_time.to_i))
      a
    end

  end
end
