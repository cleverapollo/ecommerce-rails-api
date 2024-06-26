##
# Обработчик пачки дайджейстной рассылки.
#
class DigestMailingBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, queue: 'mailing'

  # @return [DigestMailingBatch]
  attr_accessor :batch
  # @return [Shop]
  attr_accessor :shop
  # @return [ShopEmail]
  attr_accessor :current_email
  # @return [DigestMailing]
  attr_accessor :mailing
  # @return [DigestMail]
  attr_accessor :current_digest_mail

  # Запустить рассылку пачки.
  #
  # @param id [Integer] ID пачки рассылки.
  def perform(id)
    self.batch = DigestMailingBatch.find(id)
    return if batch.completed?
    self.mailing = batch.mailing
    self.shop = Shop.find(mailing.shop_id)
    @settings = shop.mailings_settings
    unless @settings.enabled?
      Rollbar.warn "Mailings disabled for shop #{shop.id}"
      return
    end

    # Не обрабатываем новые пачки, если рассылка ранее дохла.
    if mailing.failed?
      return
    end

    # Проверяем количество писем в спаме перед началом пачки, минимальное для вхождения 5000
    if mailing.sent_mails_count >= 5000 && mailing.mails.bounced.count.to_f / mailing.sent_mails_count.to_f * 100.0 >= 1 && mailing.id != 1694137785654444042
      mailing.update(state: 'spam')
      shop.update(mailings_restricted: true)
      Rollbar.warn "Spam bounced detect #{shop.id}"
      return
    end

    DigestMailingRecommendationsCalculator.open(shop, mailing.amount_of_recommended_items) do |calculator|
      if batch.test_mode?
        # Тестовый режим: генерируем тестовое письмо для пустого пользователя и отправляем его на тестовый адрес.
        recommendations = calculator.recommendations_for(nil)
        send_mail(batch.test_email, recommendations, nil)

        # Отмечаем пачку как завершенную.
        batch.complete!
      else

        # Полноценный режим.
        if batch.current_processed_client_id.nil?
          batch.current_processed_client_id = batch.start_id
        end

        # Для юзера без истории и профиля здесь будем хранить дефолтный набор рекомендаций, чтобы каждый раз его не рассчитывать
        empty_user_recommendations = nil

        # Проходим по всей доступной аудитории
        relation = shop.shop_emails.with_clients.suitable_for_digest_mailings.where(id: batch.current_processed_client_id.value.to_i..batch.end_id).order(:id)

        relation = relation.with_clients_segment(batch.segment_ids) if batch.segment_ids.present?
        relation = relation.without_clients_segment(batch.exclude_segment_ids) if batch.exclude_segment_ids.present?

        # Добавляем список id в выборку из пачки (увеличивет скорость выборки в 24 раза)
        relation = relation.where(id: batch.client_ids) if batch.client_ids.present?

        # Проходим по пачке клиентов
        relation.select('shop_emails.*, clients.id AS client_id').each do |shop_email|

          # Каждый раз запоминаем текущий обрабатываемый ID
          self.current_email = shop_email
          batch.update current_processed_client_id: current_email.id

          # Пропускаем, если в текущей рассылке уже было отправлено письмо
          next if mailing.mails.where(shop_email: shop_email).exists?

          # Создаем письмо
          self.current_digest_mail = batch.digest_mails.create!(shop: shop, client_id: current_email.client_id, shop_email: shop_email, mailing: mailing).reload

          # Для юзера без профиля будем использовать дефолтный набор рекомендаций, чтобы каждый раз его не рассчитывать
          if current_email.client_id.nil?
            recommendations = calculator.recommendations_for(nil)
          else
            if empty_user_recommendations.nil?
              empty_user_recommendations = calculator.recommendations_for(current_digest_mail.client.user)
            end
            recommendations = empty_user_recommendations
          end

          send_mail(current_email.email, recommendations, current_digest_mail.client.try(:user))
          # STDOUT.write " #{current_email.user.id}: mail: #{t_m.round(2)} ms, recommendations: #{t_r.round(2)} ms\n"
          mailing.sent_mails_count.increment
        end

        # Отмечаем пачку как завершенную.
        batch.complete!

        # Завершаем рассылку, если все пачки завершены.
        mailing.finish! if mailing.batches.incomplete.none?
      end
    end

  rescue Sidekiq::Shutdown => e
    Rollbar.warn e
    sleep 5
    retry
  rescue Exception => e
    mailing.fail! if mailing && !batch.test_mode?
    raise e
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  # Отправить письмо.
  #
  # @param email [String] e-mail.
  # @param recommendations [Array] массив рекомендаций.
  def send_mail(email, recommendations, location)
    # if Rails.env.production?
    #   # t_m = Benchmark.ms {
    #     m = Mailings::DefaultMail.compose(shop, to: email,
    #                                 subject: mailing.subject,
    #                                 from: @settings.send_from,
    #                                 body: liquid_letter_body(recommendations, email, location),
    #                                 text: text_version(recommendations, email, location),
    #                                 type: 'digest',
    #                                 code: current_digest_mail.try(:code),
    #                                 unsubscribe_url: unsubscribe_url(current_email),
    #                                 list_id: "<digest shop-#{shop.id} id-#{mailing.id} date-#{Date.current.strftime('%Y-%m-%d')}>",
    #                                 feedback_id: "mailing#{mailing.id}:shop#{shop.id}:digest:rees46mailer")
    #   # }
    #   m.deliver!
    #   #t_d = Benchmark.ms { m.deliver! }
    #   #STDOUT.write " shop: #{shop.id}, user: #{email}, mail compose: #{t_m.round(2)} ms, mail deliver_now: #{t_d.round(2)} ms\n"
    # else
      Mailings::SignedEmail.compose(shop, to: email,
                                    subject: mailing.subject,
                                    from: @settings.send_from,
                                    body: liquid_letter_body(recommendations, email, location),
                                    text: text_version(recommendations, email, location),
                                    type: 'digest',
                                    code: current_digest_mail.try(:code),
                                    unsubscribe_url: unsubscribe_url(current_email),
                                    list_id: "<digest shop-#{shop.id} id-#{mailing.id} date-#{Date.current.strftime('%Y-%m-%d')}>",
                                    feedback_id: "mailing#{mailing.id}:shop#{shop.id}:digest:rees46mailer").deliver_now
    # end
  end



  # Сформировать тело письма из ликвидного шаблона.
  #
  # @param items [Array] массив товаров.
  # @param email [String] E-mail покупателя
  # @param location [String] Код локации получателя письма для локальной цены
  def liquid_letter_body(items, email, location)

    # "Зашифрованный" e-mail для вшивания в ссылки для того, чтобы после перехода склеить пользователя
    track_email = Base64.encode64( (current_email.try(:email) || email).to_s ).strip

    template = mailing.liquid_template.dup
    data = {
      utm_params: "utm_source=rees46&utm_medium=digest_mail&utm_campaign=digest_mail_#{Time.current.strftime('%d.%m.%Y')}&recommended_by=digest_mail&rees46_digest_mail_code=#{current_digest_mail.try(:code) || 'test'}&r46_merger=#{track_email}",
      logo_url: (shop.fetch_logo_url.blank? ? '' : shop.fetch_logo_url),
      footer: Mailings::Composer.footer(email: current_email.try(:email) || email, tracking_url: current_digest_mail.try(:tracking_url) || DigestMail.new(shop_id: shop.id).tracking_url, unsubscribe_url: unsubscribe_url(current_email)),
      email: current_email.try(:email) || email,
      tracking_url: current_digest_mail.try(:tracking_url) || DigestMail.new(shop_id: shop.id).tracking_url,
      unsubscribe_url: unsubscribe_url(current_email)
    }
    data[:recommended_items] = items.map { |item| item_for_letter(item, location, track_email, mailing.images_dimension) }
    data[:tracking_pixel] = "<img src='#{data[:tracking_url]}' alt=''></img>"

    template = Liquid::Template.parse template
    html = template.render data.deep_stringify_keys

    # Добавляем к ссылкам уникальные ключи для отслеживания карты переходов
    doc = Nokogiri::HTML.parse(html)
    i = 0
    doc.css('a[href]').each do |a|
      begin
        uri = Addressable::URI.parse(a.attribute('href').value)
      rescue Addressable::URI::InvalidURIError => e
        Rollbar.error(e, href: a.attribute('href').value, shop: shop.id)
        raise e
      end
      if /^http/.match(uri.scheme)
        uri_params = Rack::Utils.parse_nested_query((uri.query || '').gsub(/%([^a-z0-9])/, '%25\\1'))
        uri_params[:utm_link_map] = i
        uri.query = uri_params.to_query
        i += 1
        a.attribute('href').value = uri.to_s
      end
    end
    doc.to_html
  end

  # Формирует текстовую версию
  def text_version(items, email, location)

    # "Зашифрованный" e-mail для вшивания в ссылки для того, чтобы после перехода склеить пользователя
    track_email = Base64.encode64( (current_email.try(:email) || email).to_s ).strip

    template = mailing.text_template.present? ? mailing.text_template.dup : ''
    data = {
      utm_params: "utm_source=rees46&utm_medium=digest_mail&utm_campaign=digest_mail_#{Time.current.strftime('%d.%m.%Y')}&recommended_by=digest_mail&rees46_digest_mail_code=#{current_digest_mail.try(:code) || 'test'}&r46_merger=#{track_email}",
      logo_url: (shop.fetch_logo_url.blank? ? '' : shop.fetch_logo_url),
      footer: Mailings::Composer.footer(email: current_email.try(:email) || email, tracking_url: current_digest_mail.try(:tracking_url) || DigestMail.new(shop_id: shop.id).tracking_url, unsubscribe_url: unsubscribe_url(current_email)),
      email: current_email.try(:email) || email,
      tracking_url: current_digest_mail.try(:tracking_url) || DigestMail.new(shop_id: shop.id).tracking_url,
      unsubscribe_url: unsubscribe_url(current_email)
    }
    data[:recommended_items] = items.map { |item| item_for_letter(item, location, track_email, mailing.images_dimension) }

    template = Liquid::Template.parse template
    template.render(data.deep_stringify_keys)
  end

  # @param [ShopEmail] shop_email
  def unsubscribe_url(shop_email)
    Routes.unsubscribe_subscriptions_url(type: 'digest', code: shop_email.try(:code) || 'test', host: Rees46::HOST, shop_id: self.shop.uniqid, mail_code: current_digest_mail.try(:code) || 'test')
  end




  # Обертка над товаром для отображения в письме.
  #
  # @param item [Item] товар.
  # @param location [String] Код локации для локальной цены
  # @param track_email [String] Зашифрованный емейл для склеивания юзера после перехода
  # @raise [Mailings::NotWidgetableItemError] исключение, если у товара нет необходимых параметров.
  # @return [Hash] обертка.
  def item_for_letter(item, location, track_email = "", images_dimension = nil)
    price = item.price_at_location(location)
    raise Mailings::NotWidgetableItemError.new(item) unless item.widgetable?
    {
      name: item.name,
      description: item.description.to_s,
      price_formatted: ActiveSupport::NumberHelper.number_to_rounded(price, precision: 0, delimiter: " "),
      oldprice_formatted: item.oldprice.present? ? ActiveSupport::NumberHelper.number_to_rounded(item.oldprice, precision: 0, delimiter: " ") : nil,
      price: price.to_i,
      price_full: price.to_f,
      price_full_formatted: ActiveSupport::NumberHelper.number_to_rounded(price, precision: 2, delimiter: ' '),
      oldprice: item.oldprice.to_i,
      url: UrlParamsHelper.add_params_to(item.url, {
           rees46_source: 'digest_mail',
           rees46_campaign: "digest_mail_#{Time.current.strftime("%d.%m.%Y")}",
           recommended_by: 'digest_mail',
           rees46_digest_mail_code: current_digest_mail.try(:code) || 'test',
           r46_merger: track_email
      }),
      image_url: (images_dimension ? item.resized_image_by_dimension(images_dimension) : item.image_url),
      currency: shop.currency,
      id: item.uniqid.to_s,
      barcode: item.barcode.to_s,
      brand: item.brand.to_s,
      amount: 1,
      leftovers: item.leftovers,
    }
  end
end
