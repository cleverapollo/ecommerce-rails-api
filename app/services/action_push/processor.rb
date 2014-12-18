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
      if params.trigger_mail_code.present? &&
         trigger_mail = TriggerMail.find_by(code: params.trigger_mail_code)
        trigger_mail.mark_as_clicked!
      end

      # Обработка дайджестных писем
      if params.digest_mail_code.present? &&
         digest_mail = DigestMail.find_by(code: params.digest_mail_code)
        digest_mail.mark_as_clicked!
      end

      params.items.each do |item|
        action = fetch_action_for item
        action.process params

        Interaction.push(user_id: params.user.id,
                         shop_id: params.shop.id,
                         item_id: item.id,
                         type: action.name_code,
                         recommended_by: params.recommended_by)
      end

      concrete_action_class.mass_process(params)

      params.shop.report_event(params.action.to_sym)
    end

    def fetch_action_for(item)
      a = concrete_action_class.find_or_initialize_by user_id: params.user.id, shop_id: params.shop.id, item_id: item.id
      a.assign_attributes \
                          price: item.price,
                          timestamp: (params.date || Date.current.to_time.to_i)

      a
    end
  end
end
