module TriggerMailings
  ##
  # Класс, отвечающий за обработку пользователей магазинов.
  #
  class ClientsProcessor

    class << self
      # Обработать всех пользователей: искать для каждого триггеры, если есть - отправить письмо.
      def process_all
        Shop.connected.active.unrestricted.with_yml_processed_recently.with_enabled_triggers.each do |shop|

          # Запрещаем отправку сообщений при не настроенном DNS
          # todo пока отключили, ждем отмашки от Кечинова
          # next unless shop.mailing_dig_verify?

          # Клиент на MailChimp временно отключен
          next if shop.id == 2442

          # Не даем рассылать триггеры тем магазинам, у кого нет денег и нет активных подписок или нет активных оплаченных подписок
          next if shop.customer.balance < 0 && !shop.subscription_plans.trigger_emails.active.exists? || shop.subscription_plans.trigger_emails.active.exists? && !shop.subscription_plans.trigger_emails.active.paid.exists?

          # Запускаем в очередь
          TriggerMailingWorker.perform_async(shop.id)
        end
      end
    end

  end
end
