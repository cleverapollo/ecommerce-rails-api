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
      result += "  baseURL: 'http://#{Rees46::HOST}',"
      result += "  testingGroup: #{shop.ab_testing? ? session.user.ab_testing_group_in(shop) : 0},"
      result += "  currency: '#{shop.currency}',"
      result += "  showPromotion: false,"
      result += "  segments: [],"
      result += "  sync: #{get_sync_pixels(session, shop).to_json},"

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
      subscriptions_plan = shop.subscription_plans.subscriptions.first
      products = nil
      if shop.subscriptions_enabled? && shop.subscriptions_settings.products?
        recommender_ids = shop.actions.where(user: session.user).where('view_count > 0').order('view_date DESC').limit(5).pluck(:item_id)
        if recommender_ids.count > 0
          products = shop.items.recommendable.widgetable.available.where(id: recommender_ids).limit(3).pluck(:url, :image_url, :name, :price, :uniqid)
        end
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
            type: 0,
            timer: 90,
        }

        if subscriptions_plan.present? && subscriptions_plan.paid?
          email_settings = email_settings.merge({
            type: shop.subscriptions_settings.popup_type,
            timer: shop.subscriptions_settings.timer_enabled? ? shop.subscriptions_settings.timer : 0,
            pager: shop.subscriptions_settings.pager_enabled? ? shop.subscriptions_settings.pager : 0,
            cursor: shop.subscriptions_settings.cursor_enabled? ? shop.subscriptions_settings.cursor : 0,
            products: products,
            products_title: I18n.t('email_settings.products_title', locale: shop.customer.language || 'en'),
            products_buy: I18n.t('email_settings.buy', locale: shop.customer.language || 'en'),
          })
        end
      end

      result = {
          ssid: session.code,
          currency: shop.currency,
          profile: session.user.profile_to_json,
          has_email: client.email.present?,
          shop_debug: shop.debug_order,
          sync: get_sync_pixels(session, shop),
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
          webPushSubscription: {
              settings: if shop.web_push_subscriptions_enabled?
                          {
                              enabled: shop.web_push_subscriptions_settings.enabled,
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
      result
    end



    # Get array of syncronization pixels for DMP.
    # @param session [Session]
    # @param shop [Shop]
    # @return Array
    def get_sync_pixels(session, shop)
      # return [] # Отключено, потому что смущают магазины. А массивных продаж данных пока нет.
      pixels = []
      if shop && (shop.remarketing_enabled? || shop.match_users_with_dmp?)
        # if session.synced_with_aidata_at.nil? || session.synced_with_aidata_at < Date.current
        #   pixels << "//x01.aidata.io/0.gif?pid=REES46&id=#{session.code}"
        #   session.update synced_with_aidata_at: Date.current
        # end
        # if session.synced_with_dca_at.nil? || session.synced_with_dca_at < Date.current
        #   pixels << "//front.facetz.net/collect?source=rees46&pixel_id=686&id=#{session.code}"
        #   session.update synced_with_dca_at: Date.current
        # end
        # if session.synced_with_auditorius_at.nil? || session.synced_with_auditorius_at < Date.current
        #   pixels << "//sync.audtd.com/match/rs?pid=#{session.code}"
        #   session.update synced_with_auditorius_at: Date.current
        # end
        # if session.synced_with_amber_at.nil? || session.synced_with_amber_at < Date.current
        #   pixels << "//dmg.digitaltarget.ru/1/2026/i/i?a=26&e=#{session.code}&i=#{rand}"
        #   session.update synced_with_amber_at: Date.current
        # end
        # if session.synced_with_mailru_at.nil? || session.synced_with_mailru_at < Date.current
        #   pixels << "//ad.mail.ru/cm.gif?p=74&id=#{session.code}"
        #   session.update synced_with_mailru_at: Date.current
        # end
        if session.synced_with_relapio_at.nil? || session.synced_with_relapio_at < Date.current
          pixels << "//relap.io/api/partners/rscs.gif?uid=#{session.code}"
          session.update synced_with_relapio_at: Date.current
        end
        if session.synced_with_republer_at.nil? || session.synced_with_republer_at < Date.current
          pixels << "//sync.republer.com/match?dsp=rees46&id=#{session.code}&dnr=1"
          session.update synced_with_republer_at: Date.current
        end
        if session.synced_with_advmaker_at.nil? || session.synced_with_advmaker_at < Date.current
          pixels << "//rtb.am15.net/aux/sync?advm_nid=68280&uid=#{session.code}"
          session.update synced_with_advmaker_at: Date.current
        end

      end

      if shop && shop.id == 725 && false
        pixels << '//api.rees46.com/pix/auditory.png'
      end

      pixels
    end



  end
end
