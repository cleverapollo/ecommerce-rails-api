##
# Обработчик поступающих событий
#
module ActionPush
  class Processor

    # @return [ActionPush::Params]
    attr_reader :params
    attr_reader :concrete_action_class

    # @param [ActionPush::Params] params
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
      if params.r46_returner_code.present? && params.r46_returner_code != 'test' && rtb_impression = RtbImpression.find_by(code: params.r46_returner_code)
        rtb_impression.mark_as_clicked!
        if params.action.to_sym == :purchase
          rtb_impression.mark_as_purchased!
        end
      end

      # Обработка веб пуш триггеров
      if params.web_push_trigger_code.present? && params.web_push_trigger_code != 'test' && message = WebPushTriggerMessage.find_by(code: params.web_push_trigger_code)
        message.mark_as_clicked!
      end

      # Обработка веб пуш дайджестов
      if params.web_push_digest_code.present? && params.web_push_digest_code != 'test' && message = WebPushDigestMessage.find_by(code: params.web_push_digest_code)
        message.mark_as_clicked!
      end

      # Для каждого переданного товара запускаем процессинг действия
      params.items.each do |item|

        # Находим действие по отношению к товару.
        action = fetch_action_for item

        # Запускаем обработку действия
        action.process params

        # Трекаем событие
        Actions::Tracker.new(params).track(item)

        # Логгируем событие
        Interaction.push(user_id: params.user.id, shop_id: params.shop.id, item_id: item.id, type: action.name_code, recommended_by: params.recommended_by, segments: params.segments)

      end

      # Это используется в покупках и при передаче полного содержимого корзины
      concrete_action_class.mass_process(params)

      # Корректируем характеристики профиля покупателя для отраслевых товаров
      if params.items.any?
        ProfileEvent.track_items params.user, params.shop, params.action, params.items, params.niche_attributes
      end

      # Сообщаем, что от магазина пришло событие
      params.shop.report_event(params.action.to_sym)

      # Если пришла корзина и она пуста или товаров больше одного (используется массовая корзина), сообщаем о событии "удалено из корзины"
      if params.action.to_sym == :cart && params.items.count != 1
        params.shop.report_event(:remove_from_cart)
      end

      # Отмечаем, что пользователь был активен
      params.client.track_last_activity

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
