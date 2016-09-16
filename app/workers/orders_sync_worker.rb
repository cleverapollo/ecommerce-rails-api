##
# Класс, ответственный за синхронизацию статусов заказов магазина. Работает в фоне
#
class OrdersSyncWorker
  class OrdersSyncError < StandardError; end

  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  def perform(opts)

    begin

      current_shop = Shop.find_by!(uniqid: opts['shop_id'], secret: opts['shop_secret'])

      if opts['orders'].nil? || !opts['orders'].is_a?(Array)
        raise OrdersSyncError.new('Не передан массив заказов')
      end
      if opts['orders'].none?
        raise OrdersSyncError.new('Пустой массив заказов')
      end

      opts['orders'].each do |element|

        if element["id"].blank?
          raise OrdersSyncError.new("Передан заказ без ID: #{element}")
        end
        if element["status"].blank?
          raise OrdersSyncError.new("Передан заказ ##{element["id"]} без статуса")
        end

        current_order = Order.find_by uniqid: element["id"], shop_id: current_shop.id

        if current_order

          # Если статус "Отменен" и ранее статус был не "Отменен" и при этом заказ был сделан раньше, чем сегодня
          # (то есть счет за CPA уже был выставлен) и заказ еще не был компенсирован, то компенсируем комиссию
          # При этом дата заказа должна быть не старше 1 месяца.
          if element["status"].to_i == Order::STATUS_CANCELLED && current_order.refundable?
            current_order.update! compensated: true
            current_shop.customer.change_balance CpaReport.fee(current_order, current_shop)
          end

          current_order.change_status element["status"].to_i

        end

      end


      # Отмечаем дату последней синхронизации заказов и сообщаем об этом в Slack
      if opts['orders'].any?
        if current_shop.last_orders_sync.nil?
          begin
            if Rails.env.production? # << -- не забудь вернуть, если уберешь - менеджеров смущает мусор в слаке
              notifier = Slack::Notifier.new Rails.application.secrets.slack_notify_key, username: "Shop #{current_shop.id}", http_options: { open_timeout: 1 }
              notifier.ping("Just got first orders statuses sync. https://rees46.com/shops/#{current_shop.id}" )
            end
          rescue Exception => e
            Rollbar.error e
          end
        end
        current_shop.update last_orders_sync: Time.current
      end


    rescue OrdersSyncError => e
      email = opts['errors_to'] || current_shop.customer.email
      ErrorsMailer.orders_import_error(email, e.message, opts).deliver_now
    end
  end


end
