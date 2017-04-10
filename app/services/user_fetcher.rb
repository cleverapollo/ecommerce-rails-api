##
# Класс, отвечающий за поиск пользователя по определенным входящим параметрам.
#
class UserFetcher
  class SessionNotFoundError < StandardError;
  end

  attr_reader :external_id, :session_code, :shop, :email, :location
  # @return [Client]
  attr_accessor :client
  # @return [Session]
  attr_accessor :session

  def initialize(params)
    # Если external_id указан, он корректный
    @external_id = params[:external_id] if external_id.present? && external_id.to_s != '0' && external_id.to_i >= 0
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
      self.client = shop.clients.find_or_create_by!(user_id: self.session.user_id)
    rescue ActiveRecord::RecordNotUnique
      self.client = shop.clients.find_by!(user_id: self.session.user_id)
    end

    if location.present? && (self.client.location.nil? || self.client.location != location.to_s)
      self.client.update(location: location)
    end

    user = self.client.user

    if email.present?
      user = UserMerger.merge_by_mail(shop, self.client, email)
      self.client = user.clients.where(shop_id: shop.id).limit(1)[0]
    end

    # Если известен ID пользователя в магазине
    if external_id.present? && (self.client.external_id.nil? || self.client.external_id != external_id)
      if old_client = shop.clients.where.not(id: self.client.id).find_by(external_id: external_id)
        # И при этом этот ID есть у другой связки
        # Значит, нужно сливать этих двух пользователей
        user = UserMerger.merge(old_client.user, self.client.user)
      else
        # И при этом этого ID больше нигде нет
        # Запоминаем его для текущего пользователя
        # Адовый способ не ломать транзакцию
        exclude_query = "NOT EXISTS (SELECT 1 FROM clients WHERE shop_id = ? and external_id = ?)"
        shop.clients.where(id: self.client.id).where(exclude_query, shop.id, external_id).update_all(external_id: external_id)
        user = self.client.user
      end
    end


    user
  end
end
