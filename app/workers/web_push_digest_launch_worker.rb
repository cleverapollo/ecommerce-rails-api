##
# Обработчик запуска дайджестной рассылки.
#
class WebPushDigestLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'mailing'

  attr_reader :shop

  BATCH_SIZE = 20

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

    # Если недостаточно аудитории, отмечаем рассылку проваленной и прекращаем работу
    if audience_relation.count > shop.web_push_balance
      web_push_digest.fail!
      return
    end

    if web_push_digest.batches.incomplete.none?
      audience_relation.each_batch_with_start_end_id(BATCH_SIZE) do |start_id, end_id|
        web_push_digest.batches.create!(start_id: start_id, end_id: end_id, shop_id: shop.id)
      end
    end

    # Запоминаем, сколько пользователей попало в рассылку для счетчика
    # Записываем время и дату запуска рассылки
    web_push_digest.update(total_mails_count: audience_relation.count, started_at: Time.current)

    # Запускаем обработчики на все пачки
    web_push_digest.batches.incomplete.each do |batch|
      DigestMailingBatchWorker.perform_async(batch.id)
    end
  end
end
