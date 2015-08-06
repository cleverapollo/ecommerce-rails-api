##
# Обработчик пачки дайджейстной рассылки.
#
class DigestMailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'mailing'

  attr_accessor :mailing, :current_client, :current_digest_mail

  # Запустить рассылку пачки.
  #
  # @param id [Integer] ID пачки рассылки.
  def perform(id)
    @batch = DigestMailingBatch.find(id)
    @mailing = @batch.mailing
    @shop = Shop.find(@mailing.shop_id)
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
        # Подчистим память перед рассылкой следующей порции дайджеста
        # Медленней, зато с меньшим потреблением памяти
        #GC.start

        # Полноценный режим.
        if @batch.current_processed_client_id.nil?
          @batch.current_processed_client_id = @batch.start_id
        end

        # Проходим по всей доступной аудитории
        @shop.clients.suitable_for_digest_mailings.includes(:user)
             .where(id: @batch.current_processed_client_id.value.to_i..@batch.end_id).each do |client|
          # Каждый раз запоминаем текущий обрабатываемый ID
          @current_client = client
          @batch.current_processed_client_id = @current_client.id

          @current_digest_mail = @batch.digest_mails.create!(shop: @shop, client: @current_client, mailing: @mailing).reload

          recommendations = []
          if IncomingDataTranslator.email_valid?(@current_client.email)
            RecommendationsRequest.report do |r|

              recommendations = calculator.recommendations_for(@current_client.user)

              send_mail(@current_client.email, recommendations)

              r.shop = @shop
              r.recommender_type = 'digest_mail'
              r.recommendations = recommendations.map(&:uniqid)
              r.user_id = @current_client.user.present? ? @current_client.user.id : 0
            end
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
    Mailings::SignedEmail.compose(@shop, to: email,
                                  subject: @mailing.subject,
                                  from: @settings.send_from,
                                  body: letter_body(recommendations, email),
                                  type: 'digest',
                                  code: @current_digest_mail.try(:code)).deliver_now
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
    utm = "utm_source=rees46&utm_medium=digest_mail&utm_campaign=digest_mail_#{Time.current.strftime('%d.%m.%Y')}&recommended_by=digest_mail&rees46_digest_mail_code=#{@current_digest_mail.try(:code) || 'test'}"
    result.gsub!('{{ utm_params }}', utm)

    # Cтавим логотип
    - if MailingsSettings.using(@shop.shard_name).where(shop_id: @shop.id).first.fetch_logo_url.blank?
      result.sub!(/<img(.*?)<\/tr>/m," ")
    - else
      result.gsub!('{{ logo_url }}', MailingsSettings.using(@shop.shard_name).where(shop_id: @shop.id).first.fetch_logo_url)

    # Добавляем футер
    footer = Mailings::Composer.footer(email: @current_client.try(:email) || email,
                                       tracking_url: @current_digest_mail.try(:tracking_url) || DigestMail.new.tracking_url,
                                       unsubscribe_url: @current_client.try(:digest_unsubscribe_url) || Client.new.digest_unsubscribe_url)
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
      url: UrlParamsHelper.add_params_to(item.url, utm_source: 'rees46',
                                             utm_medium: 'digest_mail',
                                             utm_campaign: "digest_mail_#{Time.current.strftime("%d.%m.%Y")}",
                                             recommended_by: 'digest_mail',
                                             rees46_digest_mail_code: @current_digest_mail.try(:code) || 'test'),
      image_url: item.image_url,
      currency: item.shop.currency
    }
  end
end
