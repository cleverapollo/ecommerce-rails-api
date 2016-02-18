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

    def process

      # Обработка триггерных писем
      if params.trigger_mail_code.present? && params.trigger_mail_code != 'test' &&
          trigger_mail = TriggerMail.find_by(code: params.trigger_mail_code)
        trigger_mail.mark_as_clicked!
      end

      # Обработка дайджестных писем
      if params.digest_mail_code.present? && params.digest_mail_code != 'test' &&
          digest_mail = DigestMail.find_by(code: params.digest_mail_code)
        digest_mail.mark_as_clicked!
      end

      # Для каждого переданного товара запускаем процессинг действия
      params.items.each do |item|
        action = fetch_action_for item
        action.process params

        # Логгируем событие
        Interaction.push(user_id: params.user.id,
                         shop_id: params.shop.id,
                         item_id: item.id,
                         type: action.name_code,
                         recommended_by: params.recommended_by)

      end

      # Это используется в покупках
      concrete_action_class.mass_process(params)

      # Активируем триггеры отраслевых алгоритмов
      SectoralAlgorythms::Service.new(params.user, SectoralAlgorythms::Service.all_virtual_profile_fields)
          .trigger_action(params.action, params.items)

      # Сообщаем, что от магазина пришло событие
      params.shop.report_event(params.action.to_sym)

      # Отмечаем, что пользователь был активен
      Client.find_by(user_id: params.user.id, shop_id: params.shop.id).track_last_activity

      # Трекаем таксономию в DMP
      UserTaxonomy.track params.user, params.items, params.shop, params.action

    end

    def fetch_action_for(item)
      a = concrete_action_class.find_or_initialize_by(user_id: params.user.id,
                                                      shop_id: params.shop.id,
                                                      item_id: item.id)
      a.assign_attributes(timestamp: (params.date || Date.current.to_time.to_i))

      a
    end
  end
end
