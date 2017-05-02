##
# Класс, отвечающий за поиск пользователя по определенным входящим параметрам.
#
class UserFetcher
  class SessionNotFoundError < StandardError
  end

  attr_reader :external_id, :session_code, :shop, :email, :location
  # @return [Client]
  attr_accessor :client
  # @return [Session]
  attr_accessor :session

  def initialize(params)
    # Если external_id указан, он корректный
    @external_id = params[:external_id] if params[:external_id].present? && params[:external_id].to_s != '0' && params[:external_id].to_i >= 0
    @session_code = params.fetch(:session_code)
    @shop = params.fetch(:shop)
    @email = IncomingDataTranslator.email(params[:email])
    @location = params[:location]
  end

  def fetch
    # Сессия должна существовать
    self.session = Session.find_by(code: session_code)
    raise SessionNotFoundError if self.session.blank?

    # Находим или создаем связку пользователя с магазином
    begin
      self.client = shop.clients.find_or_create_by!(user_id: session.user_id)
    rescue ActiveRecord::RecordNotUnique
      self.client = shop.clients.find_by!(user_id: session.user_id)
    end

    if location.present? && (client.location.nil? || client.location != location.to_s)
      client.update(location: location)
    end

    user = client.user

    if email.present?
      begin
        user = UserMerger.merge_by_mail(shop, client, email)
        self.client = user.clients.find_by!(shop_id: shop.id)
      rescue ActiveRecord::RecordNotFound => e
        Rollbar.error(e, shop_id: shop.id, client: client.id, client_email: client.email, email: email)
        return nil
      end
    end

    # Если известен ID пользователя в магазине
    if external_id.present? && (client.external_id.nil? || client.external_id != external_id)
      old_client = shop.clients.where.not(id: client.id).find_by(external_id: external_id)
      if old_client.present?
        # И при этом этот ID есть у другой связки
        # Значит, нужно сливать этих двух пользователей
        user = UserMerger.merge(old_client.user, client.user)
      else
        # И при этом этого ID больше нигде нет
        # Запоминаем его для текущего пользователя
        # Адовый способ не ломать транзакцию
        exclude_query = 'NOT EXISTS (SELECT 1 FROM clients WHERE shop_id = ? and external_id = ?)'
        shop.clients.where(id: client.id).where(exclude_query, shop.id, external_id).update_all(external_id: external_id)
        user = client.user
      end
    end


    user
  end
end
