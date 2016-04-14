##
# Обработчик пачки дайджейстной рассылки.
#
class DigestMailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, queue: 'mailing'

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
        send_mail(@batch.test_email, recommendations, nil)

        # Отмечаем пачку как завершенную.
        @batch.complete!
      else

        # Полноценный режим.
        if @batch.current_processed_client_id.nil?
          @batch.current_processed_client_id = @batch.start_id
        end

        # Проходим по всей доступной аудитории
        relation = @shop.clients.suitable_for_digest_mailings.includes(:user).where(id: @batch.current_processed_client_id.value.to_i..@batch.end_id).order(:id)
        relation = relation.where('activity_segment is not null and activity_segment = ?', @batch.activity_segment) unless @batch.activity_segment.nil?
        relation.each do |client|

          # Каждый раз запоминаем текущий обрабатываемый ID
          @current_client = client
          @batch.update current_processed_client_id: @current_client.id

          @current_digest_mail = @batch.digest_mails.create!(shop: @shop, client: @current_client, mailing: @mailing).reload

          recommendations = []
          if IncomingDataTranslator.email_valid?(@current_client.email)
            RecommendationsRequest.report do |r|

              recommendations = calculator.recommendations_for(@current_client.user)

              send_mail(@current_client.email, recommendations, @current_client.location)

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
  def send_mail(email, recommendations, location)
    Mailings::SignedEmail.compose(@shop, to: email,
                                  subject: @mailing.subject,
                                  from: @settings.send_from,
                                  body: letter_body(recommendations, email, location),
                                  type: 'digest',
                                  code: @current_digest_mail.try(:code)).deliver_now
  end

  # Сформировать тело письма.
  #
  # @param items [Array] массив товаров.
  # @param email [String] E-mail покупателя
  # @param location [String] Код локации получателя письма для локальной цены
  def letter_body(items, email, location)

    # "Зашифрованный" e-mail для вшивания в ссылки для того, чтобы после перехода склеить пользователя
    track_email = Base64.encode64( (@current_client.try(:email) || email).to_s )

    result = @mailing.template.dup

    # Вставляем в письмо товары
    items.each do |item|
      item_template = @mailing.item_template.dup
      decorated_item = item_for_letter(item, location, track_email)

      decorated_item.each do |key, value|
        item_template.gsub!("{{ #{key} }}", value)
        item_template.gsub!(/\{\{\s+name\s+limit=([0-9]+)\s+\}\}/) { limit = "#{$1}".to_i; (value[0,limit] + '...') } if key.to_s == 'name'
      end

      result['{{ recommended_item }}'] = item_template
    end

    # Убираем оставшиеся метки, если рекомендаций вернулось меньше, чем нужно
    result.gsub!('{{ recommended_item }}', '')

    # Убираем лишнее.
    result.gsub!(/\{\{ user.\w+ }}/, '')

    # UTM
    utm = "utm_source=rees46&utm_medium=digest_mail&utm_campaign=digest_mail_#{Time.current.strftime('%d.%m.%Y')}&recommended_by=digest_mail&rees46_digest_mail_code=#{@current_digest_mail.try(:code) || 'test'}&r46_merger=#{track_email}"
    result.gsub!('{{ utm_params }}', utm)

    # Cтавим логотип
    if MailingsSettings.where(shop_id: @shop.id).first.fetch_logo_url.blank?
      result.sub!(/<img(.*?)<\/tr>/m," ")
    else
      result.gsub!('{{ logo_url }}', MailingsSettings.where(shop_id: @shop.id).first.fetch_logo_url)
    end

    # Добавляем футер
    footer = Mailings::Composer.footer(email: @current_client.try(:email) || email,
                                       tracking_url: @current_digest_mail.try(:tracking_url) || DigestMail.new(shop_id: @shop.id).tracking_url,
                                       unsubscribe_url: @current_client.try(:digest_unsubscribe_url) || Client.new(shop_id: @shop.id).digest_unsubscribe_url)
    result['{{ footer }}'] = footer

    result
  end

  # Обертка над товаром для отображения в письме.
  #
  # @param [Item] товар.
  # @param location [String] Код локации для локальной цены
  # @param track_email [String] Зашифрованный емейл для склеивания юзера после перехода
  # @raise [Mailings::NotWidgetableItemError] исключение, если у товара нет необходимых параметров.
  # @return [Hash] обертка.
  def item_for_letter(item, location, track_email = "")
    raise Mailings::NotWidgetableItemError.new(item) unless item.widgetable?
    {
      name: item.name,
      description: item.description,
      price: ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(location), precision: 0, delimiter: " "),
      url: UrlParamsHelper.add_params_to(item.url, utm_source: 'rees46',
                                             utm_medium: 'digest_mail',
                                             utm_campaign: "digest_mail_#{Time.current.strftime("%d.%m.%Y")}",
                                             recommended_by: 'digest_mail',
                                             rees46_digest_mail_code: @current_digest_mail.try(:code) || 'test',
                                             r46_merger: track_email
                                        ),
      image_url: item.image_url,
      currency: item.shop.currency,
    }
  end
end
