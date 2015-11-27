module TriggerMailings
  ##
  # Класс, отвечающий за обработку пользователей магазинов.
  #
  class ClientsProcessor

    class << self
      # Обработать всех пользователей: искать для каждого триггеры, если есть - отправить письмо.
      def process_all

        TriggersLogger.log "Check sending available"

        if TriggerMailings::TriggerMailingTimeLock.new.sending_available?

          TriggersLogger.log "Start sending"

          TriggerMailings::TriggerMailingTimeLock.new.start_sending!

          TriggersLogger.log "Sending started"

          Shop.unrestricted.with_valid_yml.with_enabled_triggers.each do |shop|

            TriggersLogger.log "Process shop #{shop.id}"

            TriggerMailings::TriggerDetector.for(shop) do |trigger_detector|

              TriggersLogger.log "Trigger detectorЛогг defined"

              clients =
                if trigger_detector.triggers_classes.include?(TriggerMailings::Triggers::SecondAbandonedCart) && shop.allow_industrial?
                  ( shop.clients.ready_for_trigger_mailings(shop) + shop.clients.ready_for_second_abandoned_cart(shop) ).uniq
                else
                  shop.clients.ready_for_trigger_mailings(shop)
                end

              TriggersLogger.log "Clients found: #{clients.count}"


              clients.each do |client|
                TriggersLogger.log "Process client #{client.id}"
                begin
                  if trigger = trigger_detector.detect(client)
                    TriggersLogger.log "Trigger found: #{trigger.class.name}"
                    TriggerMailings::Letter.new(client, trigger).send
                    TriggersLogger.log "Message sent to #{client.email}"
                    client.update_columns(last_trigger_mail_sent_at: Time.now)
                    TriggersLogger.log "Last trigger mail sent at updated"
                  end
                rescue StandardError => e
                  TriggersLogger.log "Error appeared: #{e}"
                  Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
                end

                TriggersLogger.log "Client #{client.id} processed"

              end

              TriggersLogger.log "Clients for shop #{shop.id} done"

            end
          end

          TriggersLogger.log "All shops done"

          TriggerMailings::TriggerMailingTimeLock.new.stop_sending!

          TriggersLogger.log "Lock released"

        else
          TriggersLogger.log "Sending not available"
        end

        TriggersLogger.log "Sending finished. End of operation"

      end
    end

  end
end
