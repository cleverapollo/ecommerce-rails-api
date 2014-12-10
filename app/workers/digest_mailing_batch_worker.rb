##
# Обработчик пачки дайджейстной рассылки.
#
class DigestMailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'mailing'

  # Запустить рассылку пачки.
  #
  # @param id [Integer] ID пачки рассылки.
  def perform(id)
    @batch = DigestMailingBatch.find(id)
    @mailing = @batch.mailing
    @shop = @mailing.shop
    @settings = @shop.digest_mailing_setting

    unless @settings.on?
      raise DigestMailing::DisabledError, "Рассылки отключены для магазина #{@shop.id}"
    end

    # Не обрабатываем новые пачки, если рассылка ранее дохла.
    if @mailing.failed?
      return
    end

    recommendations_count = @mailing.template.scan('{{ recommended_item }}').count

    DigestMailingRecommendationsCalculator.open(@shop, recommendations_count) do |calculator|
      if @batch.test_mode?
        # Тестовый режим: генерируем тестовое письмо для пустого пользователя и отправляем его на тестовый адрес.
        recommendations = calculator.recommendations_for(nil)
        send_mail(@batch.test_email, recommendations, {})

        # Отмечаем пачку как завершенную.
        @batch.complete!
      else
        # Полноценный режим.
        if @batch.current_processed_audience_id.nil?
          @batch.current_processed_audience_id = @batch.start_id
        end

        # Проходим по всей доступной аудитории
        @shop.audiences.enabled.includes(:user)
             .where(id: @batch.current_processed_audience_id.value.to_i..@batch.end_id).each do |audience|
          # Каждый раз запоминаем текущий обрабатываемый ID
          @batch.current_processed_audience_id = audience.id
          # Каждый раз пытаемся прикрепить "аудиторию" к пользователю нашей системы
          audience.try_to_attach_to_user!

          if IncomingDataTranslator.email_valid?(audience.email)
            recommendations = calculator.recommendations_for(audience.user)

            send_mail(audience.email, recommendations, audience.custom_attributes)
          end
          @mailing.sent_mails_count.increment
        end

        # Отмечаем пачку как завершенную.
        @batch.complete!

        # Завершаем рассылку, если все пачки завершены.
        @mailing.finish! if @mailing.batches.incomplete.none?
      end
    end
  rescue => e
    @mailing.fail! if @mailing
    raise e
  end

  # Отправить письмо.
  #
  # @param email [String] e-mail.
  # @param recommendations [Array] массив рекомендаций.
  # @param custom_attributes = {} [Hash] кастомные аттрибуты пользователя.
  def send_mail(email, recommendations, custom_attributes = {})
    Mailer.digest(
      email: email,
      subject: @mailing.subject,
      send_from: @settings.sender,
      body: letter_body(recommendations, custom_attributes)
    ).deliver
  end

  # Сформировать тело письма.
  #
  # @param items [Array] массив товаров.
  # @param custom_attributes = {} [Hash] кастомные аттрибуты пользователя.
  def letter_body(items, custom_attributes = {})
    result = @mailing.template.dup

    # Вставляем в письмо товары
    items.each do |item|
      item_template = @mailing.item_template.dup
      decorated_item = item_for_letter(item)

      decorated_item.each do |key, value|
        item_template.gsub!("{{ #{key} }}", value)
      end

      result['{{ recommended_item }}'] = item_template
    end

    # Вставляем в письмо кастомные аттрибуты пользователя.
    custom_attributes.each do |key, value|
      result.gsub!("{{ user.#{key} }}", value)
    end

    # Убираем лишнее.
    result.gsub!(/\{\{ user.\w+ }}/, '')

    result
  end

  # Обертка над товаром для отображения в письме.
  #
  # @param [Item] товар.
  # @raise [Mailings::NotWidgetableItemError] исключение, если у товара нет необходимых параметров.
  # @return [Hash] обертка.
  def item_for_letter(item)
    raise Mailings::NotWidgetableItemError.new(item) unless item.widgetable?
    {
      name: item.name,
      description: item.description,
      price: ActiveSupport::NumberHelper.number_to_rounded(item.price, precision: 0, delimiter: "'"),
      url: UrlHelper.add_params_to(item.url, utm_source: 'rees46',
                                             utm_meta: 'digest_mail',
                                             utm_campaign: "digest_mail_#{Time.current.strftime("%d.%m.%Y")}",
                                             recommended_by: 'digest_mail'),
      image_url: item.image_url
    }
  end
end
