##
# Обработчик пачки дайджейстной рассылки.
#
class DigestMailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'mailing'

  attr_accessor :mailing, :current_shops_user, :current_digest_mail

  # Запустить рассылку пачки.
  #
  # @param id [Integer] ID пачки рассылки.
  def perform(id)
    @batch = DigestMailingBatch.find(id)
    @mailing = @batch.mailing
    @shop = @mailing.shop
    @settings = @shop.mailings_settings

    unless @settings.enabled?
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
        send_mail(@batch.test_email, recommendations)

        # Отмечаем пачку как завершенную.
        @batch.complete!
      else
        # Полноценный режим.
        if @batch.current_processed_shops_user_id.nil?
          @batch.current_processed_shops_user_id = @batch.start_id
        end

        # Проходим по всей доступной аудитории
        @shop.shops_users.suitable_for_digest_mailings.includes(:user)
             .where(id: @batch.current_processed_shops_user_id.value.to_i..@batch.end_id).each do |shops_user|
          # Каждый раз запоминаем текущий обрабатываемый ID
          @current_shops_user = shops_user
          @batch.current_processed_shops_user_id = @current_shops_user.id

          @current_digest_mail = @batch.digest_mails.create!(shop: @shop, shops_user: @current_shops_user, mailing: @mailing).reload

          if IncomingDataTranslator.email_valid?(@current_shops_user.email)
            recommendations = calculator.recommendations_for(@current_shops_user.user)

            send_mail(@current_shops_user.email, recommendations)
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
  def send_mail(email, recommendations)
    Mailings::SignedEmail.deliver(@shop, to: email,
                                     subject: @mailing.subject,
                                     from: @settings.send_from,
                                     body: letter_body(recommendations, email),
                                     type: 'digest',
                                     code: @current_digest_mail.try(:code))
  end

  # Сформировать тело письма.
  #
  # @param items [Array] массив товаров.
  # @param custom_attributes = {} [Hash] кастомные аттрибуты пользователя.
  def letter_body(items, email)
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

    # if custom_attributes.present? && custom_attributes.any?
    #   # Вставляем в письмо кастомные аттрибуты пользователя.
    #   custom_attributes.each do |key, value|
    #     result.gsub!("{{ user.#{key} }}", value)
    #   end
    # end

    # Убираем лишнее.
    result.gsub!(/\{\{ user.\w+ }}/, '')

    # UTM
    d_m_code =
    utm = "utm_source=rees46&utm_meta=digest_mail&utm_campaign=digest_mail_#{Time.current.strftime('%d.%m.%Y')}&recommended_by=digest_mail&rees46_digest_mail_code=#{@current_digest_mail.try(:code) || 'test'}"
    result.gsub!('{{ utm_params }}', utm)

    # Добавляем футер
    footer = Mailings::Composer.footer(email: @current_shops_user.try(:email) || email,
                                       tracking_url: @current_digest_mail.try(:tracking_url) || DigestMail.new.tracking_url,
                                       unsubscribe_url: @current_shops_user.try(:digest_unsubscribe_url) || ShopsUser.new.digest_unsubscribe_url)
    result['{{ footer }}'] = footer

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
                                             recommended_by: 'digest_mail',
                                             rees46_digest_mail_code: @current_digest_mail.try(:code) || 'test'),
      image_url: item.image_url
    }
  end
end
