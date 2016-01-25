module TriggerMailings
  ##
  # Класс, отвечающий за обработку пользователей магазинов.
  #
  class ClientsProcessor

    class << self
      # Обработать всех пользователей: искать для каждого триггеры, если есть - отправить письмо.
      def process_all

        if TriggerMailings::TriggerMailingTimeLock.new.sending_available?

          TriggerMailings::TriggerMailingTimeLock.new.start_sending!

          Shop.unrestricted.with_valid_yml.with_enabled_triggers.each do |shop|

            TriggerMailings::TriggerDetector.for(shop) do |trigger_detector|

              clients = shop.clients.ready_for_trigger_mailings(shop) + shop.clients.ready_for_second_abandoned_cart(shop)

              # clients =
              #   if trigger_detector.triggers_classes.include?(TriggerMailings::Triggers::SecondAbandonedCart) && shop.allow_industrial?
              #     ( shop.clients.ready_for_trigger_mailings(shop) + shop.clients.ready_for_second_abandoned_cart(shop) ).uniq
              #   else
              #     shop.clients.ready_for_trigger_mailings(shop)
              #   end

              clients.each do |client|

                begin
                  if trigger = trigger_detector.detect(client)
                    TriggerMailings::Letter.new(client, trigger).send
                    client.update_columns(last_trigger_mail_sent_at: Time.now)
                    client.update_columns(supply_trigger_sent: true) if trigger.class == TriggerMailings::Triggers::LowOnSupply
                  end
                rescue StandardError => e
                  Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
                end

              end
            end
          end

          TriggerMailings::TriggerMailingTimeLock.new.stop_sending!
        end

      end
    end

  end
end
