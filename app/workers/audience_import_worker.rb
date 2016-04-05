##
# Воркер, импортирующий аудиторию дайджестных рассылок.
# Вызывается со стороны /rees46-rails
#
class AudienceImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    @shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    params.fetch('audience').each do |a|
      id = a.fetch('id').to_s.strip
      email = IncomingDataTranslator.email(a.fetch('email'))

      # next if id.blank? && email.blank?
      # Не доделано http://y.mkechinov.ru/issue/REES-2317
      # # Если есть емейл и идентификатор
      # if id.present? && email.present?
      #   client_with_email = shop.clients.find_by(email: email)
      #   # А что, если клиент с емейлом все же не найден в базе?
      #   if client_with_email.external_id != id
      #     client_with_id = shop.clients.find_by(external_id: id)
      #     # Если пользователи разные
      #     if client_with_id.user_id != client_with_email.user_id
      #       # Молодого к старому
      #       UserMerger.merge([client_with_id.user_id, client_with_email.user_id].min, [client_with_id.user_id, client_with_email.user_id].max)
      #     else
      #       # Пользователи одинаковые, удаляем нового и присваиваем старого клиента
      #       Client.relink_user(from: [client_with_id.id, client_with_email.id].min, to: [client_with_id.id, client_with_email.id].max )
      #     end
      #   end
      #   next
      # end
      #
      # # Если есть только емейл
      # if id.blank? && email.present?
      #
      #   next
      # end
      #
      # # Если есть только ID, игнорируем
      # if id.present? && email.blank?
      #   next
      # end


      next if id.blank? || email.blank?
      client = shop.clients.find_by(external_id: id)
      if client.blank?
        client = shop.clients.find_by(email: email)
        if client.blank?
          client = shop.clients.build(external_id: id, user: User.create)
        end
      end

      client.email = email || client.email

      client.save!
    end
  end
end
