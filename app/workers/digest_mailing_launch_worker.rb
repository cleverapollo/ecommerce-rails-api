##
# Обработчик запуска дайджестной рассылки.
class DigestMailingLaunchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'mailing'

  # @return [Shop]
  attr_reader :shop

  BATCH_SIZE = 200
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

    # @type [Shop] shop
    shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))
    digest_mailing = shop.digest_mailings.find(params.fetch('id'))
    settings = shop.mailings_settings

    if params['test_email'].present?
      if settings.external_mailchimp? && digest_mailing.mailchimp_attr_present?

        MailchimpTestDigestLetter.perform_async(digest_mailing_id: digest_mailing.id,
                                                api_key: settings.mailchimp_api_key,
                                                test_email: params['test_email'])
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
            digest_mailing.batches.create!(mailchimp_count: MAILCHIMP_BATCH_SIZE, mailchimp_offset: offset, shop_id: shop.id, segment_ids: digest_mailing.segment_ids, exclude_segment_ids: digest_mailing.exclude_segment_ids)
            offset += MAILCHIMP_BATCH_SIZE
          end
        end
        digest_mailing.update(total_mails_count: all_audience)

      else

        if shop.double_opt_in_by_law?
          # Выбираем только подтвердивших email
          audience_relation = shop.shop_emails.email_confirmed.suitable_for_digest_mailings
        else
          audience_relation = shop.shop_emails.suitable_for_digest_mailings
        end

        # Добавляем JOIN клиентов
        audience_relation = audience_relation.with_clients

        # Добавляем фильтрацию по сегменту
        audience_relation = audience_relation.with_clients_segment(digest_mailing.segment_ids) if digest_mailing.segment_ids.present?
        audience_relation = audience_relation.without_clients_segment(digest_mailing.exclude_segment_ids) if digest_mailing.exclude_segment_ids.present?

        if digest_mailing.batches.incomplete.not_test.none?
          Slavery.on_slave do
            # Если пачки не были ранее созданы, то создаем пачки на всю аудиторию.
            audience_relation.select(:id).find_in_batches(batch_size: BATCH_SIZE) do |group|
              ids = group.map(&:id)
              Slavery.on_master do
                digest_mailing.batches.create!(start_id: ids.min, end_id: ids.max, shop_id: shop.id, segment_ids: digest_mailing.segment_ids, exclude_segment_ids: digest_mailing.exclude_segment_ids, client_ids: ids)
              end
            end
          end
        end
        # Запоминаем, сколько пользователей попало в рассылку
        digest_mailing.update(total_mails_count: audience_relation.size)

        if audience_relation.size == 0
          digest_mailing.finish!
        end

      end

      # Запоминаем дату и время запуска
      digest_mailing.update(started_at: Time.current)
    end

    # Запускаем обработчики на все пачки
    digest_mailing.batches.incomplete.each do |batch|
      if settings.external_mailchimp? && digest_mailing.mailchimp_attr_present?
        begin
          Mailings::Mailchimp::DigestMailingMailchimpBatch.new(batch, settings.mailchimp_api_key).btach_execute
        rescue => e
          digest_mailing.fail!
          Rollbar.warn('Mailchimp ERROR', e, params)
        end
      else
        if params['test_email'].present?
          DigestMailingBatchWorker.set(queue: 'mailing_test').perform_async(batch.id)
        else
          DigestMailingBatchWorker.perform_async(batch.id)
        end
      end
    end

    begin
      Mailings::Mailchimp::DigestSender.new(digest_mailing, settings.mailchimp_api_key).send if settings.external_mailchimp? && params['test_email'].blank? && !digest_mailing.failed?
    rescue => e
      raise e unless Rails.env.production?
      digest_mailing.fail!
      Rollbar.warn('Mailchimp ERROR', e, params)
    end

  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end
