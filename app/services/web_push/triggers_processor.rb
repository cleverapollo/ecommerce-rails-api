# Класс, отвечающий за рассылку веб пуш триггеров.
class WebPush::TriggersProcessor

  class << self

    def process_all

      # Не рассылается сейчас?
      if WebPush::TriggerTimeLock.new.sending_available?

        # Отмечаем, что рассылка идет
        WebPush::TriggerTimeLock.new.start_sending!

        # Все магазины с включенными веб пуш триггерами
        Shop.unrestricted.with_valid_yml.with_enabled_web_push_triggers.each do |shop|

          WebPush::TriggerDetector.for(shop) do |trigger_detector|

            # Сначала перебираем вторые брошенные корзины
            if trigger_detector.triggers_classes.include?(WebPush::Triggers::SecondAbandonedCart)
              shop.clients.ready_for_second_abandoned_cart_web_push(shop).find_each do |client|
                begin
                  if trigger = trigger_detector.detect(client)
                    WebPush::TriggerMessage.new(client, trigger).send
                    client.update_columns(last_web_push_sent_at: Time.now)
                    client.update_columns(supply_trigger_sent: true) if trigger.class == WebPush::Triggers::LowOnSupply
                  end
                rescue StandardError => e
                  Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
                end
              end
            end


            # Затем перебираем обычные триггеры
            shop.clients.ready_for_web_push_trigger(shop).find_each do |client|
              begin
                if trigger = trigger_detector.detect(client)
                  WebPush::TriggerMessage.new(client, trigger).send
                  client.update_columns(last_web_push_sent_at: Time.now)
                  client.update_columns(supply_trigger_sent: true) if trigger.class == WebPush::Triggers::LowOnSupply
                end
              rescue StandardError => e
                Rollbar.error(e, client_id: client.try(:id), detector: trigger_detector.inspect, trigger: (defined?(trigger) ? trigger.inspect : nil)  )
              end
            end


          end

        end

        # Отмечаем, что рассылка завершена
        WebPush::TriggerTimeLock.new.stop_sending!

      end


    end


  end


end