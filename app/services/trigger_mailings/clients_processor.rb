module TriggerMailings
  ##
  # Класс, отвечающий за обработку пользователей магазинов.
  #
  class ClientsProcessor
    class << self
      # Обработать всех пользователей: искать для каждого триггеры, если есть - отправить письмо.
      def process_all
        Shop.with_enabled_triggers.each do |shop|
          TriggerMailings::TriggerDetector.for(shop) do |trigger_detector|
            shop.clients.suitable_for_trigger_mailings.find_each do |client|
              if client.last_trigger_mail_sent_at.present? &&
                 client.last_trigger_mail_sent_at >= 2.weeks.ago
                 next
              end

              if trigger = trigger_detector.detect(client)
                TriggerMailings::Letter.new(client, trigger).send
                client.update_columns(last_trigger_mail_sent_at: Time.now)
              end
            end
          end
        end
      end
    end
  end
end
