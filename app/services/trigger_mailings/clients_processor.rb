module TriggerMailings
  ##
  # Класс, отвечающий за обработку пользователей магазинов.
  #
  class ClientsProcessor

    class << self
      # Обработать всех пользователей: искать для каждого триггеры, если есть - отправить письмо.
      def process_all
        CustomLogger.logger.info("START: TriggerMailings::ClientsProcessor.process_all")

        if TriggerMailings::TriggerMailingTimeLock.new.sending_available?

          TriggerMailings::TriggerMailingTimeLock.new.start_sending!

          Shop.unrestricted.with_valid_yml.with_yml_processed_recently.with_enabled_triggers.each do |shop|
            CustomLogger.logger.info("- start shop: #{shop.id}")

            # Не даем рассылать триггеры тем магазинам, у кого нет денег и при этом нет оплаченных подписок
            next if shop.customer.balance < 0 && !shop.subscription_plans.rees46_triggers.paid.exists?

            TriggerMailings::TriggerDetector.for(shop) do |trigger_detector|

              # Настройки рассылки для тех, кто использует внешний транспорт
              if shop.mailings_settings.external_getresponse?
                begin
                  get_response_client = Mailings::GetResponseClient.new(shop).prepare
                rescue StandardError => e
                  # TODO уведомлять клиента по почте
                  Rollbar.error(e)
                  next
                end
              end

              trigers_to_send = {} if shop.mailings_settings.external_mailchimp?

              # Сначала перебираем вторые брошенные корзины
              if trigger_detector.triggers_classes.include?(TriggerMailings::Triggers::SecondAbandonedCart)
                shop.clients.ready_for_second_abandoned_cart(shop).find_each do |client|
                  begin
                    if trigger = trigger_detector.detect(client)
                      if shop.mailings_settings.external_getresponse?
                        TriggerMailings::GetResponseLetter.new(client, trigger, get_response_client).send
                      elsif shop.mailings_settings.external_ofsys?
                        result = TriggerMailings::OfsysLetter.new(client, trigger).send
                        next unless result
                      elsif shop.mailings_settings.is_optivo_for_mytoys?
                        TriggerMailings::OptivoMytoysLetter.new(client, trigger).send
                      elsif shop.mailings_settings.external_mailchimp?
                        trigers_to_send[:second_abandoned_cart].present? ? trigers_to_send[:second_abandoned_cart] << trigger :  trigers_to_send[:second_abandoned_cart] = [trigger]
                      else
                        TriggerMailings::Letter.new(client, trigger).send
                      end
                      unless shop.mailings_settings.external_mailchimp?
                        client.update_columns(last_trigger_mail_sent_at: Time.now)
                        client.update_columns(supply_trigger_sent: true) if trigger.class == TriggerMailings::Triggers::LowOnSupply
                      end
                    end
                  rescue StandardError => e
                    Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
                  end
                end
              end

              # Затем перебираем обычные триггеры
              shop.clients.ready_for_trigger_mailings(shop).find_each do |client|
                begin
                  if trigger = trigger_detector.detect(client)
                    if shop.mailings_settings.external_getresponse?
                      TriggerMailings::GetResponseLetter.new(client, trigger, get_response_client).send
                    elsif shop.mailings_settings.external_ofsys?
                      result = TriggerMailings::OfsysLetter.new(client, trigger).send
                      next unless result
                    elsif shop.mailings_settings.is_optivo_for_mytoys?
                      TriggerMailings::OptivoMytoysLetter.new(client, trigger).send
                    elsif shop.mailings_settings.external_mailchimp?
                      trigger_type = trigger.class.to_s.gsub(/\A(.+::)(.+)\z/, '\2').underscore.to_sym
                      trigers_to_send[trigger_type].present? ? trigers_to_send[trigger_type] << trigger :  trigers_to_send[trigger_type] = [trigger]
                    else
                      TriggerMailings::Letter.new(client, trigger).send
                    end
                    unless shop.mailings_settings.external_mailchimp?
                      client.update_columns(last_trigger_mail_sent_at: Time.now)
                      client.update_columns(supply_trigger_sent: true) if trigger.class == TriggerMailings::Triggers::LowOnSupply
                    end
                  end
                rescue StandardError => e
                  Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
                end
              end

              begin
                Mailings::Mailchimp::TriggersSender.new(trigers_to_send, shop.mailings_settings.mailchimp_api_key, shop.id).send_all if shop.mailings_settings.external_mailchimp? && trigers_to_send.present?
              rescue StandardError => e
                Rollbar.error(e, mailchimp_trigger: shop.id)
              end
            end

            CustomLogger.logger.info("- end shop: #{shop.id}\n")
          end

          TriggerMailings::TriggerMailingTimeLock.new.stop_sending!
        end
        CustomLogger.logger.info("END: TriggerMailings::ClientsProcessor.process_all")
      end
    end

  end
end
