module InitServerString
  class << self
    # Шаблон JS-кода, который отдается магазину при инициализации покупателя
    # @param session
    # @param shop
    # @return string
    def make(options = {})
      shop = options.fetch(:shop)
      session = options.fetch(:session)

      result  = "REES46.initServer({"
      result += "  ssid: '#{session.code}',"
      result += "  baseURL: 'http://#{Rees46::HOST}',"
      result += "  testingGroup: #{shop.ab_testing? ? session.user.ab_testing_group_in(shop) : 0},"
      result += "  currency: '#{shop.currency}',"
      result += "  showPromotion: false,"

      # Поиск связки пользователя и магазина
      s_u = begin
        shop.clients.find_or_create_by!(user_id: session.user_id)
      rescue ActiveRecord::RecordNotUnique => e
        shop.clients.find_by!(user_id: session.user_id)
      end

      # Настройки сбора e-mail
      result += "  subscriptions: {"
      if shop.subscriptions_enabled? && s_u.email.blank?
        result += "  settings: #{shop.subscriptions_settings.to_json}, "
        if shop.subscriptions_settings.has_picture?
           result += "  picture_url: '#{shop.subscriptions_settings.picture_url}',"
        end
        result += "  user: {"
        result += "    declined: #{s_u.subscription_popup_showed == true && s_u.accepted_subscription == false}"
        result += "  }"
      end
      result += "  }"

      result += "});"
      result
    end
  end
end
