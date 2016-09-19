##
# Обработчик запуска дайджестной рассылки.
#
class DigestMailingLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'mailing'

  attr_reader :shop

  BATCH_SIZE = 20
  MAILCHIMP_BATCH_SIZE = 200

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
    settings = shop.mailings_settings

    if params['test_email'].present?
      if settings.external_mailchimp? && digest_mailing.mailchimp_attr_present?

        MailchimpTestDigestLetter.perform_async({digest_mailing_id: digest_mailing.id, api_key: settings.mailchimp_api_key, test_email: params['test_email']});
      else
        # Режим тестового письма.
        # Создаем одну тестовую пачку.
        digest_mailing.batches.create(test_email: params['test_email'], shop_id: shop.id)
      end
    else

      # Режим полноценной рассылки.
      if settings.external_mailchimp? && digest_mailing.mailchimp_attr_present?

        # Для Mailchimp
        all_audience = Mailings::Mailchimp::DigestMailerHelper.all_audience(settings.mailchimp_api_key, digest_mailing.mailchimp_list_id)

        if digest_mailing.batches.incomplete.not_test.none?
          # Если пачки не были ранее созданы, то создаем пачки на всю аудиторию.
          offset = 0
          while offset < all_audience
            digest_mailing.batches.create!(mailchimp_count: MAILCHIMP_BATCH_SIZE, mailchimp_offset: offset, shop_id: shop.id, activity_segment: digest_mailing.activity_segment)
            offset += MAILCHIMP_BATCH_SIZE
          end
        end
        digest_mailing.update(total_mails_count: all_audience)

      else

        # Для всех остальных
        audience_relation = shop.clients.suitable_for_digest_mailings
        audience_relation = audience_relation.where('activity_segment is not null and activity_segment = ?', digest_mailing.activity_segment) unless digest_mailing.activity_segment.nil?

        if digest_mailing.batches.incomplete.not_test.none?

          # Если пачки не были ранее созданы, то создаем пачки на всю аудиторию.
          audience_relation.each_batch_with_start_end_id(BATCH_SIZE) do |start_id, end_id|
            digest_mailing.batches.create!(start_id: start_id, end_id: end_id, shop_id: shop.id, activity_segment: digest_mailing.activity_segment)
          end
        end
        # Запоминаем, сколько пользователей попало в рассылку
        digest_mailing.update(total_mails_count: audience_relation.count)

      end

      # Запоминаем дату и время запуска
      digest_mailing.update(started_at: Time.current)
    end

    # Запускаем обработчики на все пачки
    digest_mailing.batches.incomplete.each do |batch|
      if settings.external_mailchimp? && digest_mailing.mailchimp_attr_present?
        Mailings::Mailchimp::DigestMailingMailchimpBatch.new(batch, settings.mailchimp_api_key).btach_execute
      else
        DigestMailingBatchWorker.perform_async(batch.id)
      end
    end

    Mailings::Mailchimp::DigestSender.new(digest_mailing, settings.mailchimp_api_key).send if settings.external_mailchimp? && params['test_email'].blank?

  end
end
