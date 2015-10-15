##
# Класс, отвечающий за поиск пользователя по определенным входящим параметрам.
#
class UserFetcher
  class SessionNotFoundError < StandardError;
  end

  attr_reader :external_id, :session_code, :shop, :email, :location

  def initialize(params)
    @external_id = params[:external_id]
    @session_code = params.fetch(:session_code)
    @shop = params.fetch(:shop)
    @email = params[:email]
    @location = params[:location]
  end

  def fetch
    # Сессия должна существовать
    session = Session.find_by(code: session_code)
    raise SessionNotFoundError if session.blank?

    client = nil
    # Находим или создаем связку пользователя с магазином
    begin
      client = shop.clients.find_or_create_by!(user_id: session.user_id)
    rescue ActiveRecord::RecordNotUnique
      client = shop.clients.find_by!(user_id: session.user_id)
    end

    result = client.user

    if location.present?
      client.update(location: location)
    end

    if email.present?
      client_email = @email
      # Найдем пользователя с тем же мылом в данном магазине
      if client_with_current_mail = shop.clients.where.not(id: client.id).find_by(email: client_email)
        old_user = client_with_current_mail.user
        client_with_current_mail.each { |merge_client| UserMerger.merge(old_user, merge_client.user) unless merge_client.user.id==old_user.id }
      else
        # И при этом этого мыла больше нигде нет
        # Запоминаем его для текущего пользователя
        # Адовый способ не ломать транзакцию
        exclude_query = "NOT EXISTS (SELECT 1 FROM clients WHERE shop_id = #{shop.id} and email = '#{client_email}')"
        shop.clients.where(id: client.id).where(exclude_query).update_all(email: client_email)
      end
    end

    # Если известен ID пользователя в магазине
    if external_id.present?
      if old_client = shop.clients.where.not(id: client.id).find_by(external_id: external_id)
        # И при этом этот ID есть у другой связки
        # Значит, нужно сливать этих двух пользователей
        UserMerger.merge(old_client.user, client.user)
        result = old_client.user
      else
        # И при этом этого ID больше нигде нет
        # Запоминаем его для текущего пользователя
        # Адовый способ не ломать транзакцию
        exclude_query = "NOT EXISTS (SELECT 1 FROM clients WHERE shop_id = #{shop.id} and external_id = '#{external_id}')"
        shop.clients.where(id: client.id).where(exclude_query).update_all(external_id: external_id)
      end
    end

    result
  end
end
