##
# Обработчик поступающих событий
#
module ActionPush
  class Processor

    # @return [ActionPush::Params]
    attr_reader :params
    # attr_reader :concrete_action_class

    # @param [ActionPush::Params] params
    def initialize(params)
      @params = params
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

        # Логгируем событие
        Interaction.push(user_id: params.user.id, shop_id: params.shop.id, item_id: item.id, type: params.action, recommended_by: params.recommended_by, segments: params.segments)

      end

      # Если пришла корзина и она пуста или товаров больше одного (используется массовая корзина), трекаем добавленные и удаленные товары
      if params.action.to_sym == :cart && params.items.count != 1
        p = params.dup
        # Если товаров вообще нет, то корзина пустая
        if params.items.count == 0
          p.items = []
          p.action = 'remove_from_cart'
          Actions::Tracker.new(p).track
        else

          # Находим новые товары, которые еще не трекались
          new_items = params.items.map(&:id) - (params.client.cart.try(:items) || [])
          p.items = params.items.select { |i| new_items.include?(i.id) }
          p.action = 'cart'
          Actions::Tracker.new(p).track if p.items.any?

          # Находим удаленные товары из корзины
          removed_items = (params.client.cart.try(:items) || []) - params.items.map(&:id)
          p.items = Item.find(removed_items)
          p.action = 'remove_from_cart'
          Actions::Tracker.new(p).track if p.items.any?
        end
      else
        # Трекаем событие
        Actions::Tracker.new(params).track
      end

      # Корректируем характеристики профиля покупателя для отраслевых товаров
      if params.items.any?
        options = { niche_attributes: params.niche_attributes, session_id: params.session.id, current_session_code: params.current_session_code }
        ProfileEvent.track_items(params.user, params.shop, params.action, params.items, options)
      end

      # Отмечаем, что пользователь был активен
      params.client.track_last_activity

      # Пропускаем для категории, пока Кечинов не расскажет, что тут творится
      unless %w(category recone_view recone_click search).include?(params.action)
        # Трекаем таксономию в DMP
        UserTaxonomy.track params.user, params.items, params.shop, params.action
      end

      # Проверяем стал ли магазин подключенным
      params.shop.check_connection!
    end





    # Находит или создает действие пользователя по отношению к товару.
    # @param item [Item] Объект товара
    # @return Action
    # @deprecated
    def fetch_action_for(item)
      a = concrete_action_class.find_or_initialize_by(user_id: params.user.id, shop_id: params.shop.id, item_id: item.id)
      a.assign_attributes(timestamp: (params.date || Date.current.to_time.to_i))
      a
    end

  end
end
