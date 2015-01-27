module TriggerMailings
  ##
  # Класс, отвечающий за обработку пользователей магазинов.
  #
  class ShopsUsersProcessor
    class << self
      # Обработать всех пользователей: искать для каждого триггеры, если есть - отправить письмо.
      def process_all
        Shop.with_enabled_triggers.each do |shop|
          TriggerMailings::TriggerDetector.for(shop) do |trigger_detector|
            shop.shops_users.suitable_for_trigger_mailings.find_each do |shops_user|
              if shops_user.last_trigger_mail_sent_at.present? &&
                 shops_user.last_trigger_mail_sent_at >= 2.weeks.ago
                 next
              end

              if trigger = trigger_detector.detect(shops_user)
                TriggerMailings::Letter.new(shops_user, trigger).send
                shops_user.update_columns(last_trigger_mail_sent_at: Time.now)
              end
            end
          end
        end
      end
    end
  end
end
