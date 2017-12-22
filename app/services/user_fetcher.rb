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
    @external_id = params[:external_id].to_s if params[:external_id].present? && params[:external_id].to_s != '0' && params[:external_id].to_i > 0
    @session_code = params.fetch(:session_code)
    @shop = params.fetch(:shop)
    @email = IncomingDataTranslator.email(params[:email]) if params[:email].present?
    @location = params[:location]
  end

  def fetch
    # Сессия должна существовать
    self.session = Session.find_by_code(session_code)
    raise SessionNotFoundError if self.session.blank?

    # Находим или создаем связку пользователя с магазином
    begin
      # Новая версия, ищем клиента по сессии
      self.client = Client.find_by(session: session, shop: shop)

      # Поддержка старого метода, пробуем найти юзера, если по сессии не нашли
      if client.nil?
        self.client = Client.find_by(user: session.user, shop: shop)
      end

      # Создаем, если не найден
      if client.nil?
        self.client = Client.create!(session: session, shop: shop, user: session.user)
      elsif client.session_id.blank?
        client.session_id = session.id
        client.atomic_save!
      end
    rescue ActiveRecord::RecordNotUnique
      self.client = shop.clients.find_by!(session: session)
    end

    if location.present? && (client.location.nil? || client.location != location.to_s)
      client.location = location
      client.atomic_save if client.changed?
    end

    user = client.user

    if email.present?
      client.update_email(email)
    end

    # Удалить после 01.01.2018, если не будем клеить по external_id
    # Если известен ID пользователя в магазине
    # if external_id.present? && (client.external_id.nil? || client.external_id != external_id)
    #   old_client = shop.clients.where.not(id: client.id).find_by(external_id: external_id)
    #   if old_client.present?
    #     # И при этом этот ID есть у другой связки
    #     # Значит, нужно сливать этих двух пользователей
    #     user = UserMerger.merge(old_client.user, client.user)
    #   else
    #     # И при этом этого ID больше нигде нет
    #     # Запоминаем его для текущего пользователя
    #     # Адовый способ не ломать транзакцию
    #     exclude_query = 'NOT EXISTS (SELECT 1 FROM clients WHERE shop_id = ? and external_id = ?)'
    #     shop.clients.where(id: client.id).where(exclude_query, shop.id, external_id).update_all(external_id: external_id)
    #     user = client.user
    #   end
    # end
    if @external_id.present? && self.client.external_id.nil?
      self.client.update external_id: @external_id
    end


    user
  end
end
