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
      result += "  sync: #{get_sync_pixels(session).to_json},"

      # Настройки сбора e-mail
      result += "  subscriptions: {"
      if shop.subscriptions_enabled? && client.email.blank?
        result += "  settings: #{shop.subscriptions_settings.to_json}, "
        if shop.subscriptions_settings.has_picture?
           result += "  picture_url: '#{shop.subscriptions_settings.picture_url}',"
        end
        result += "  user: {"
        result += "    declined: #{client.subscription_popup_showed == true && client.accepted_subscription == false}"
        result += "  }"
      end
      result += "  }"

      result += "});"
      result
    end



    def get_sync_pixels(session)
      pixels = []
      pixels << "//x01.aidata.io/0.gif?pid=REES46&id=#{session.code}" if session.synced_with_aidata_at.nil? || session.synced_with_aidata_at < 2.days.ago
      pixels << "//front.facetz.net/collect?source=rees46&pixel_id=686&id=#{session.code}" if session.synced_with_dca_at.nil? || session.synced_with_dca_at < 2.days.ago
      pixels << "//sync.audtd.com/match/rs?pid=#{session.code}" if session.synced_with_auditorius_at.nil? || session.synced_with_auditorius_at < 2.days.ago
      pixels
    end



  end
end
