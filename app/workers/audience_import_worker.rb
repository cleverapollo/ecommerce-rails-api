##
# Воркер, импортирующий аудиторию дайджестных рассылок.
# Вызывается со стороны /rees46-rails
#
class AudienceImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_accessor :shop

  def perform(params)
    @shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    # Если был передан сегмент
    if params['segment_id'].present?
      segment = @shop.segments.find_by(id: params['segment_id'])
    else
      segment = nil
    end

    params.fetch('audience').each do |a|
      id = a.fetch('id').to_s.strip
      email = IncomingDataTranslator.email(a.fetch('email'))

      next if email.blank?
      id ||= ''

      # @type [Client] client
      client = @shop.clients.find_by(email: email)
      if client.blank?
        if id.present?
          client = @shop.clients.find_by(external_id: id)
          if client.blank? || client.email.present? && client.email != email
            client = @shop.clients.build(external_id: id, user: User.create)
          end
        else
          client = @shop.clients.build(user: User.create)
        end
      end

      client.email = email || client.email
      client.external_id = id if client.external_id.blank? && id.present?

      # Активируем подписку для импортируемого пользователя
      if client.email.present?
        client.digests_enabled = true
        client.triggers_enabled = true
      end

      # Добавляем сразу сегмент пользователя
      client.add_segment(segment.id) if segment.present?

      client.save! if client.changed?
    end

    # Запускаем перерасчет аудитории
    People::Segmentation::ActivityWorker.new(@shop).perform.update

    # CompletesMailer.audiance_import_completed(shop, @audiance_count).deliver_now if @audiance_count > 0
  end
end
