##
# Класс, отвечающий за поиск пользователя по определенным входящим параметрам.
#
class UserFetcher
  class SessionNotFoundError < StandardError; end

  attr_reader :external_id
  attr_reader :session_code
  attr_reader :shop
  attr_reader :email

  def initialize(params)
    @external_id = params[:external_id]
    @session_code = params.fetch(:session_code)
    @shop = params.fetch(:shop)
    @email = params[:email]
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

    if email.present?
      client.update(email: email)
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
        begin
          client.update(external_id: external_id)
        rescue ActiveRecord::RecordNotUnique

        end
      end
    end

    result
  end
end
