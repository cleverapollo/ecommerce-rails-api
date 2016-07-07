module InitServerString
  class << self
    # Шаблон JS-кода, который отдается магазину при инициализации покупателя
    # @param session
    # @param shop
    # @return string
    def make(options = {})
      shop = options.fetch(:shop)
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
          result += "  picture_url: '#{Rees46.site_url}#{shop.subscriptions_settings.picture.url(:original)}'"
        end
        result += "  user: {"
        result += "    declined: #{client.subscription_popup_showed == true && client.accepted_subscription == false}"
        result += "  }"
      end
      result += "  },"

      # Настройки подписок на web push
      result += "  web_push_subscriptions: {"
      # Подписку только если включена и при этом пользователь уже не подписался
      if client.web_push_enabled != true && shop.web_push_subscriptions_enabled?
        result += "  settings: #{shop.web_push_subscriptions_settings.to_json}, "
        if shop.web_push_subscriptions_settings.has_picture?
          result += "  picture_url: '#{Rees46.site_url}#{shop.web_push_subscriptions_settings.picture.url(:original)}'"
        end
      end
      result += "  },"


      # Profile
      result += "profile: #{session.user.profile_to_json}"

      result += "});"
      result
    end



    # Get array of syncronization pixels for DMP.
    # @param session [Session]
    # @param shop [Shop]
    # @return Array
    def get_sync_pixels(session, shop)
      pixels = []
      if shop && (shop.remarketing_enabled? || shop.match_users_with_dmp?)
        if session.synced_with_aidata_at.nil? || session.synced_with_aidata_at < Date.current
          pixels << "//x01.aidata.io/0.gif?pid=REES46&id=#{session.code}"
          session.update synced_with_aidata_at: Date.current
        end
        if session.synced_with_dca_at.nil? || session.synced_with_dca_at < Date.current
          pixels << "//front.facetz.net/collect?source=rees46&pixel_id=686&id=#{session.code}"
          session.update synced_with_dca_at: Date.current
        end
        # if session.synced_with_auditorius_at.nil? || session.synced_with_auditorius_at < Date.current
        #   pixels << "//sync.audtd.com/match/rs?pid=#{session.code}"
        #   session.update synced_with_auditorius_at: Date.current
        # end
        if session.synced_with_amber_at.nil? || session.synced_with_amber_at < Date.current
          pixels << "//dmg.digitaltarget.ru/1/2026/i/i?a=26&e=#{session.code}&i=#{rand}"
          session.update synced_with_amber_at: Date.current
        end
        if session.synced_with_mailru_at.nil? || session.synced_with_mailru_at < Date.current
          pixels << "//ad.mail.ru/cm.gif?p=74&id=#{session.code}"
          session.update synced_with_mailru_at: Date.current
        end
      end
      pixels
    end



  end
end
