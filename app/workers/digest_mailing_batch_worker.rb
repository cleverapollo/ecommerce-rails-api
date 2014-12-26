##
# Обработчик пачки дайджейстной рассылки.
#
class DigestMailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'mailing'

  attr_accessor :mailing, :current_audience, :current_digest_mail

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
        @shop.audiences.active.includes(:user)
             .where(id: @batch.current_processed_audience_id.value.to_i..@batch.end_id).each do |audience|
          # Каждый раз запоминаем текущий обрабатываемый ID
          @current_audience = audience
          @batch.current_processed_audience_id = @current_audience.id

          @current_digest_mail = @batch.digest_mails.create!(shop: @shop, audience: @current_audience, mailing: @mailing).reload

          # Каждый раз пытаемся прикрепить "аудиторию" к пользователю нашей системы
          @current_audience.try_to_attach_to_user!

          if IncomingDataTranslator.email_valid?(@current_audience.email)
            recommendations = calculator.recommendations_for(@current_audience.user)

            send_mail(@current_audience.email, recommendations, @current_audience.custom_attributes)
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
    mail = Mailer.digest(
      email: email,
      subject: @mailing.subject,
      send_from: @settings.sender,
      body: letter_body(recommendations, custom_attributes)
    )

    if @shop.id == 374
      pk = '-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQDLXfsqNbqJ5IuGh5sBKIHzG/1A33Z+7TfregL6DrrWJ3widGWd
WjxBEblZObQMDMSPzoaqSHz4Xn16Wo6SpOgAJRGqlqNM/Y4Hszgt1temZNIE7JZm
2XiAKaDrZyQJA/7h5P4pyNtsMJGjBNv5FPS6Zs+xjtIm1rswk5Mv081uuQIDAQAB
AoGBAJMqxZF8JCuZiiamh1NFPxTw0kpZ6+RaQjdTqkfO1QIYvMoqNUazgBsOenTJ
PzPhIXV33RfpMRaDOoaKddZFI+V8kgdLO8tNag5qd213TvIVq+Ij21VBBrem0Af+
8oX+JfFq7Xw/C7VwXtW3TTuHiMVOC0ZKRlwrHoiUeWIYdKoBAkEA6my8zB1ShQbC
acfM9InSZTNIaMGp6LJQ0VgRth/z63CoeEKf8U/hpNAJGbqw6aoA18g4Wc5zVAUH
flr0MUNh4QJBAN4Vfz8XFNad8VNL3hbdyv3UAPNi8dZ8k2RKinpHUvwDDDJSliKv
EUQPYl+fO0vh+A/RzlAC21QEHkrf8/DsV9kCQGkEQ2OxMxly2L8oibF22HELk0GS
mHos/7V4nZ6YG956Po55Ukt5PJ1nsNv83WogBXalNFFPAi0+f4fkWQaEqCECQQDC
aldGx9H6P7IvlU8K/YbixmE+r/O+LLhrJ8YqXZ4L+C8JLrs4CcI3rrATvbWPLHaY
grb13EpdNm2+ZmeLFZuhAkEAqhEk+hd8hbaz+pNqPd6Ya39LOOv92h0qmecXAMGz
N9f6hdTsGa1rr/LYredvxYYnwKwqnSD9Bs2lLNubMRIntA==
-----END RSA PRIVATE KEY-----'
      pk = OpenSSL::PKey::RSA.new(pk)

      Dkim.sign(mail, domain: 'tanita-romario.com.ua', selector: 'rees46', private_key: pk)
    end

    mail.deliver
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

    if custom_attributes.present? && custom_attributes.any?
      # Вставляем в письмо кастомные аттрибуты пользователя.
      custom_attributes.each do |key, value|
        result.gsub!("{{ user.#{key} }}", value)
      end
    end

    # Вставляем в письмо ссылку на отписку
    unsubscribe_url = @current_audience.present? ? @current_audience.unsubscribe_url : Audience.new.unsubscribe_url
    result.gsub!("{{ unsubscribe_url }}", unsubscribe_url)

    # Убираем лишнее.
    result.gsub!(/\{\{ user.\w+ }}/, '')

    # UTM
    d_m_code =
    utm = "utm_source=rees46&utm_meta=digest_mail&utm_campaign=digest_mail_#{Time.current.strftime('%d.%m.%Y')}&recommended_by=digest_mail&rees46_digest_mail_code=#{@current_digest_mail.try(:code) || 'test'}"
    result.gsub!('{{ utm_params }}', utm)

    # Добавляем футер
    result += footer

    result
  end


  # Сформировать футер письма, содержащий ссылку на отписку и трекинг-пиксель.
  #
  # @return [String] футер письма.
  def footer
    tracking_url = @current_digest_mail.present? ? @current_digest_mail.tracking_url : DigestMail.new.tracking_url
    <<-HTML
      <img src="#{tracking_url}" />
    HTML
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
