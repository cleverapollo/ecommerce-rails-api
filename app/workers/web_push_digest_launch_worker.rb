##
# Обработчик запуска дайджестной рассылки.
#
class WebPushDigestLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'webpush'

  BATCH_SIZE = 50

  # Запустить дайджестную рассылку.
  # Содержимое входящих параметров:
  # {
  #   'shop_id' => '1234567890',
  #   'shop_secret' => '0987654321',
  #   'id' => 5, # ID рассылки
  # }
  #
  # @param params [Hash] входящие параметры.
  def perform(params)
    shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))
    web_push_digest = shop.web_push_digests.find(params.fetch('id'))
    audience_relation = shop.clients.ready_for_web_push_digest
    web_push_digest.start!

    # Если недостаточно аудитории, отмечаем рассылку проваленной и прекращаем работу
    if (audience_relation.count - web_push_digest.sent_messages_count.to_i > shop.web_push_balance && !shop.subscription_plans.find_by(product: 'digest.webpush')) || (@shop.subscription_plans.find_by(product: 'digest.webpush') && !@shop.subscription_plans.find_by(product: 'digest.webpush').paid?))
      web_push_digest.fail!
      return
    end

    if web_push_digest.web_push_digest_batches.incomplete.none?
      audience_relation.select(:id).find_in_batches(batch_size: BATCH_SIZE) do |group|
        ids = group.map(&:id)
        web_push_digest.web_push_digest_batches.create!(start_id: ids.min, end_id: ids.max, shop_id: shop.id, client_ids: ids)
      end
    end

    # Запоминаем, сколько пользователей попало в рассылку для счетчика
    # Записываем время и дату запуска рассылки
    web_push_digest.update(total_mails_count: audience_relation.count, started_at: Time.current)

    # Запускаем обработчики на все пачки
    web_push_digest.web_push_digest_batches.incomplete.each do |batch|
      WebPushDigestBatchWorker.perform_async(batch.id)
    end

  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end
