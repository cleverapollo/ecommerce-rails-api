##
# Класс, отвечающий за поиск пользователя по определенным входящим параметрам.
#
class UserFetcher
  class SessionNotFoundError < StandardError; end

  attr_reader :external_id, :session_code, :shop, :email, :location

  def initialize(params)
    @external_id = params[:external_id]
    @session_code = params.fetch(:session_code)
    @shop = params.fetch(:shop)
    @email = IncomingDataTranslator.email(params[:email])
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

    if email.present?
      client.update(email: email)
      # client_email = @email
      # # Найдем всех пользователей с тем же мылом в данном магазине
      # clients_with_current_mail = shop.clients.where(email:client_email).order(id: :asc)
      # if clients_with_current_mail.size>1
      #   oldest_user = clients_with_current_mail.first.user
      #   clients_with_current_mail.each {|merge_client| UserMerger.merge(oldest_user, merge_client.user) unless merge_client.user.id==oldest_user.id }
      # end
    end
    if location.present?
      client.update(location: location)
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
