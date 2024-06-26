module InitServerString
  class << self
    # Шаблон JS-кода, который отдается магазину при инициализации покупателя
    # @return [String]
    def make(options = {})

      # @type [Shop] shop
      shop = options.fetch(:shop)
      shop.update(js_sdk: 2) if shop.js_sdk.nil? || shop.js_sdk != 2

      session = options.fetch(:session)
      client = options.fetch(:client)

      result  = "REES46.initServer({"
      result += "  ssid: '#{session.code}',"
      result += "  seance: '#{options.fetch(:seance)}',"
      result += "  baseURL: 'http://#{Rees46::HOST}',"
      result += "  testingGroup: #{shop.ab_testing? ? session.user.ab_testing_group_in(shop) : 0},"
      result += "  currency: '#{shop.currency}',"
      result += "  showPromotion: false,"
      result += "  segments: [],"
      result += "  sync: #{get_sync_pixels(client, shop).to_json},"
      result += "  recommendations: #{options.fetch(:recommendations)},"


      # Настройки сбора e-mail
      result += "  subscriptions: {"
      if shop.subscriptions_enabled? && client.email.blank?
        result += "  settings: #{shop.subscriptions_settings.to_json}, "
        if shop.subscriptions_settings.has_picture?
          result += "  picture_url: '#{Rees46.site_url.gsub('http:', '')}#{shop.subscriptions_settings.picture.url(:original)}', "
        end
        result += "  user: {"
        result += "    declined: #{client.subscription_popup_showed == true && client.accepted_subscription == false}"
        result += "  }"
      end
      result += "  },"

      # Настройки подписок на web push
      result += "  web_push_subscriptions: {"
      if shop.web_push_subscriptions_enabled?
        result += "  settings: #{shop.web_push_subscriptions_settings.to_json}, "
        if shop.web_push_subscriptions_settings.has_picture?
          result += "  picture_url: '#{Rees46.site_url.gsub('http:', '')}#{shop.web_push_subscriptions_settings.picture.url(:original)}', "
        end

      # Подписку только если включена и при этом пользователь уже не подписался
        if client.web_push_enabled == true
          result += "  user: {"
          result += "    status: 'accepted'"
          result += "  }"
        elsif client.web_push_subscription_popup_showed == true && client.accepted_web_push_subscription != true # Отказался
          result += "  user: {"
          result += "    status: 'declined'"
          result += "  }"
        else # Не предлагали
          result += "  user: {"
          result += "    status: null"
          result += "  }"
        end
      end
      result += "  },"


      # Profile
      result += "profile: #{session.user.profile_to_json}"

      result += "});"
      result
    end


    # Строка инициализации для API v3
    def make_v3(options = {})

      # @type [Shop] shop
      shop = options.fetch(:shop)
      shop.update(js_sdk: 3) if shop.js_sdk.nil? || shop.js_sdk != 3

      session = options.fetch(:session)
      # @type [Client] client
      client = options.fetch(:client)
      products = nil
      # @deprecated перенести в отдельный запрос на получение товаров
      # if shop.subscriptions_enabled? && shop.subscriptions_settings.products?
      #   recommender_ids = shop.actions.where(user: session.user).where('view_count > 0').order('view_date DESC').limit(5).pluck(:item_id)
      #   if recommender_ids.count > 0
      #     products = shop.items.recommendable.widgetable.available.where(id: recommender_ids).limit(3).pluck(:url, :image_url, :name, :price, :uniqid)
      #   end
      # end


      if shop.search_enabled? && shop.search_setting
        search_settings = {
            enabled: true,
            landing: shop.search_setting.landing_page,
            type: shop.search_setting.search_type,
            results_title: I18n.t('search.results', locale: shop.customer.language || 'en'),
        }
      else
        search_settings = nil
      end

      email_settings = {
          enabled: shop.subscriptions_enabled?,
      }
      if shop.subscriptions_enabled? && client.email.blank?
        email_settings = {
            enabled: shop.subscriptions_settings.enabled,
            overlay: shop.subscriptions_settings.overlay,
            header: shop.subscriptions_settings.header,
            text: shop.subscriptions_settings.text,
            button: shop.subscriptions_settings.button,
            agreement: shop.subscriptions_settings.agreement,
            successfully: shop.subscriptions_settings.successfully,
            remote_picture_url: shop.subscriptions_settings.remote_picture_url,
            type: shop.subscriptions_settings.popup_type,
            timer: shop.subscriptions_settings.timer_enabled? ? shop.subscriptions_settings.timer : 0,
            pager: shop.subscriptions_settings.pager_enabled? ? shop.subscriptions_settings.pager : 0,
            cursor: shop.subscriptions_settings.cursor_enabled? ? shop.subscriptions_settings.cursor : 0,
            products: products,
            products_title: I18n.t('email_settings.products_title', locale: shop.customer.language || 'en'),
            products_buy: I18n.t('email_settings.buy', locale: shop.customer.language || 'en'),
        }
      end

      # Получаем профиль юзера
      user_profile = client.profile.try(:to_hash)
      user_profile.delete(:id) if user_profile.present?

      result = {
          ssid: session.code,
          seance: options.fetch(:seance),
          currency: shop.currency,
          # todo после 01.02.18 оставить только hash
          profile: user_profile.to_json,
          experiments: shop.experiments.active.map { |x| {id: x.id, segments: x.segments } },
          has_email: client.email.present?,
          sync: get_sync_pixels(client, shop),
          recommendations: options.fetch(:recommendations),
          emailSubscription: {
            settings: email_settings,
            status: if client.accepted_subscription == true
                      'accepted'
                    elsif client.subscription_popup_showed == true && client.accepted_subscription != true
                      'declined'
                    else
                      nil
                    end
          },
          search: search_settings,
          webPushSubscription: {
              settings: if shop.web_push_subscriptions_enabled?
                          {
                              enabled: shop.web_push_subscriptions_settings.enabled,
                              subdomain: shop.web_push_subscriptions_settings.subdomain,
                              overlay: shop.web_push_subscriptions_settings.overlay,
                              header: shop.web_push_subscriptions_settings.header,
                              text: shop.web_push_subscriptions_settings.text,
                              button: shop.web_push_subscriptions_settings.button,
                              agreement: shop.web_push_subscriptions_settings.agreement,
                              successfully: shop.web_push_subscriptions_settings.successfully,
                              manual_mode: shop.web_push_subscriptions_settings.manual_mode,
                              remote_picture_url: shop.web_push_subscriptions_settings.remote_picture_url,
                              safari_enabled: shop.web_push_subscriptions_settings.safari_enabled?,
                              safari_id: shop.web_push_subscriptions_settings.safari_website_push_id,
                              service_worker: shop.web_push_subscriptions_settings.service_worker,
                              type: shop.web_push_subscriptions_settings.popup_type,
                              timer: shop.web_push_subscriptions_settings.timer_enabled? ? shop.web_push_subscriptions_settings.timer : 0,
                              pager: shop.web_push_subscriptions_settings.pager_enabled? ? shop.web_push_subscriptions_settings.pager : 0,
                              cursor: shop.web_push_subscriptions_settings.cursor_enabled? ? shop.web_push_subscriptions_settings.cursor : 0,
                              products: products,
                              products_title: I18n.t('email_settings.products_title', locale: shop.customer.language || 'en'),
                              products_buy: I18n.t('email_settings.buy', locale: shop.customer.language || 'en'),
                          }
                          else
                            {enabled: false}
                        end,
              status: if client.web_push_enabled
                        'accepted'
                      elsif client.web_push_subscription_popup_showed == true && client.accepted_web_push_subscription != true
                        'declined'
                      else
                        nil
                      end
          }
      }

      # Добавляем баннер вендора
      if shop.vendor_campaigns.exists?
        result[:recone] = true
      end
      result
    end



    # Get array of syncronization pixels for DMP.
    # @param client [Client]
    # @param shop [Shop]
    # @return Array
    def get_sync_pixels(client, shop)
      # return [] # Отключено, потому что смущают магазины. А массивных продаж данных пока нет.
      pixels = []
      if shop && (shop.remarketing_enabled? || shop.match_users_with_dmp?)
        if client.synced_with_republer_at.nil? || client.synced_with_republer_at < Date.current
          pixels << "//sync.republer.com/match?dsp=rees46&id=#{client.user_id}"
          client.synced_with_republer_at = Date.current
        end
        if client.synced_with_facebook_at.nil? || client.synced_with_facebook_at < Date.current
          pixels << "https://www.facebook.com/tr?id=295297477540385&ev=PageView&noscript=1"
          client.synced_with_facebook_at = Date.current
        end
        if client.synced_with_advmaker_at.nil? || client.synced_with_advmaker_at < Date.current
          pixels << "//rtb.am15.net/aux/sync?advm_nid=68280&uid=#{client.user_id}"
          client.synced_with_advmaker_at = Date.current
        end
        if client.synced_with_doubleclick_at.nil? || client.synced_with_doubleclick_at < Date.current
          # Используем ID, потому что гугл не может работать со строками длиннее 24 байт.
          pixels << "//cm.g.doubleclick.net/pixel?google_nid=rees46&google_sc&google_cm&google_hm=#{Base64.encode64(client.user_id.to_s).strip}"
          client.synced_with_doubleclick_at = Date.current
        end
        # Трекаем добавление в корзину
        if shop.remarketing_enabled? && (client.synced_with_doubleclick_cart_at.nil? || client.synced_with_doubleclick_cart_at < Date.current) && ClientCart.find_by(user_id: client.user_id, shop: shop, date: Date.current).present?
          pixels << "//googleads.g.doubleclick.net/pagead/viewthroughconversion/855802464/?guid=ON&script=0"
          client.synced_with_doubleclick_cart_at = Date.current
        end
        if shop.remarketing_enabled? && (client.synced_with_facebook_cart_at.nil? || client.synced_with_facebook_cart_at < Date.current) && ClientCart.find_by(user_id: client.user_id, shop: shop, date: Date.current).present?
          pixels << "https://www.facebook.com/tr?id=295297477540385&ev=AddToCart&noscript=1"
          client.synced_with_facebook_cart_at = Date.current
        end

        client.atomic_save! if client.changed?
      end

      pixels
    end



  end
end
