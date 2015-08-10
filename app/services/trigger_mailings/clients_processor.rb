module TriggerMailings
  ##
  # Класс, отвечающий за обработку пользователей магазинов.
  #
  class ClientsProcessor
    LAST_REFRESH_TIMEOUT = 600
    class << self
      # Обработать всех пользователей: искать для каждого триггеры, если есть - отправить письмо.
      def process_all
        if TriggerMailings::TriggerMailingTimeLock.new.sending_available?
          TriggerMailings::TriggerMailingTimeLock.new.start_sending!
          last_refresh = Time.now.to_i
          Shop.unrestricted.with_enabled_triggers.each do |shop|
            TriggerMailings::TriggerDetector.for(shop) do |trigger_detector|
              shop.clients.ready_for_trigger_mailings.each do |client|
                begin
                  if trigger = trigger_detector.detect(client)
                    TriggerMailings::Letter.new(client, trigger).send
                    client.update_columns(last_trigger_mail_sent_at: Time.now)
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
