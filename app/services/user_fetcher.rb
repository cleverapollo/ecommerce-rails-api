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
    @session_code = params.fetch(:ssid)
    @shop = params.fetch(:shop)
    @email = IncomingDataTranslator.email(params[:email]) if params[:email].present?
    @location = params[:location]
  end

  def fetch
    # Сессия должна существовать
    self.session = Session.find_by_code(session_code)
    raise SessionNotFoundError if self.session.blank? && email.blank?

    # Если не нашли сессию и есть email ищем клиента (или создаем нового)
    if session.nil? && email.present?
      # Ищем клиента по email
      self.client = Client.find_by(shop: shop, email: email)
      if client.nil?
        # Создаем нового
        begin
          self.client = Client.create!(shop: shop, user: User.create)
        rescue # Concurrency?
          self.client =  Client.find_by(shop: shop, email: email)
        end
        self.client.update(user: User.create) if client.user.nil?
        self.session = Session.find_or_create_by!(user_id: client.user_id)
      else
        # Находим его сессии
        self.session = client.session
        self.session = Session.find_or_create_by!(user_id: client.user_id) if self.session.nil?
      end
    else

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

    end

    # Если указан email, сохраняем его клиенту
    if email.present?
      client.update_email(email)
    end

    # Это наверно уже не нужно...
    if @external_id.present? && self.client.external_id.nil?
      self.client.update external_id: @external_id
    end


    client.user
  end
end
