##
# Обработчик запуска дайджестной рассылки.
#
class DigestMailingLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  # Запустить дайджестную рассылку.
  # Содержимое входящих параметров:
  # {
  #   'shop_id' => '1234567890',
  #   'shop_secret' => '0987654321',
  #   # ID рассылки
  #   'id' => 5,
  #   # Тестовое письмо (опциональный параметр)
  #   'test_email' => 'test@example.com'
  # }
  #
  # @param params [Hash] входящие параметры.
  def perform(params)
    shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))
    digest_mailing = shop.digest_mailings.find(params.fetch('id'))

    if params['test_email'].present?
      # Режим тестового письма.
      # Создаем одну тестовую пачку.
      digest_mailing.digest_mailing_batches.create(test_email: params['test_email'])
    else
      # Режим полноценной рассылки.
      # Создаем пачки на всю аудиторию.
      shop.audiences.enabled.each_batch_with_start_end_id do |start_id, end_id|
        digest_mailing.digest_mailing_batches.create!(start_id: start_id, end_id: end_id)
      end

      # Запоминаем, сколько пользователей попало в рассылку
      digest_mailing.update(total_mails_count: shop.audiences.count)
    end

    # Запускаем обработчики на все пачки
    digest_mailing.digest_mailing_batches.incomplete.each do |batch|
      DigestMailingBatchWorker.perform_async(batch.id)
    end
  end
end
