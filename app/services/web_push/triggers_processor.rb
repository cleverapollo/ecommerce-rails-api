# Класс, отвечающий за рассылку веб пуш триггеров.
class WebPush::TriggersProcessor

  class << self

    def process_all
      # Не рассылается сейчас?
      if WebPush::TriggerTimeLock.new.sending_available?

        CustomLogger.logger.info("START: WebPush::TriggersProcessor.process_all")

        # Отмечаем, что рассылка идет
        WebPush::TriggerTimeLock.new.start_sending!

        # Все магазины с включенными веб пуш триггерами
        Shop.active.connected.unrestricted.with_yml_processed_recently.with_enabled_web_push_triggers.each do
          # @type shop [Shop]
          |shop|

          # Не даем рассылать триггеры тем магазинам, у кого нет купленных пакетов
          next if (shop.web_push_balance <= 0 && !shop.subscription_plans.find_by(product: 'trigger.webpush')) || (shop.subscription_plans.find_by(product: 'trigger.webpush') && !shop.subscription_plans.find_by(product: 'trigger.webpush').paid?)

          Time.use_zone(shop.customer.time_zone) do

            CustomLogger.logger.info("START: WebPush::TriggersProcessor.process_all::SHOP_ID=#{shop.id}")

            safari_pusher = shop.web_push_subscriptions_settings.safari_config

            begin
              WebPush::TriggerDetector.for(shop) do |trigger_detector|

                # Сначала перебираем вторые брошенные корзины
                if trigger_detector.triggers_classes.include?(WebPush::Triggers::SecondAbandonedCart)
                  shop.clients.ready_for_second_abandoned_cart_web_push(shop).find_each do |client|
                    detect_trigger(trigger_detector, client, safari_pusher)
                  end
                end

                # Затем перебираем обычные триггеры
                shop.clients.ready_for_web_push_trigger(shop).find_each do |client|
                  detect_trigger(trigger_detector, client, safari_pusher)
                end

              end
            rescue WebPush::TriggerMessage::NotEnoughMoney
              next
            end

            CustomLogger.logger.info("STOP: WebPush::TriggersProcessor.process_all::SHOP_ID=#{shop.id}")

          end
        end

        # Отмечаем, что рассылка завершена
        WebPush::TriggerTimeLock.new.stop_sending!

        CustomLogger.logger.info("STOP: WebPush::TriggersProcessor.process_all")

      end
    end

    # @param trigger_detector [WebPush::TriggerDetector]
    # @param client [Client]
    # @param safari_pusher [Grocer]
    def detect_trigger(trigger_detector, client, safari_pusher)
      begin
        trigger = trigger_detector.detect(client)
        if trigger && trigger.items.present? && trigger.items.first.present?
          WebPush::TriggerMessage.new(trigger, client, safari_pusher).send
          client.update_columns(last_web_push_sent_at: Time.now)
          client.update_columns(supply_trigger_sent: true) if trigger.class == WebPush::Triggers::LowOnSupply
        end
      rescue WebPush::TriggerMessage::NotEnoughMoney => e
        raise e
      rescue StandardError => e
        Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
      end
    end


  end


end
