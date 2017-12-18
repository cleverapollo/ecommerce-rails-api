##
# Воркер, импортирующий аудиторию дайджестных рассылок.
# Вызывается со стороны /rees46-rails
#
class AudienceImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'import'

  attr_accessor :shop

  def perform(params)
    @shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    # Если был передан сегмент
    if params['segment_id'].present?
      segment = @shop.segments.find_by(id: params['segment_id'])
      segment.update(updating: true) if segment.present? && !segment.updating?
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
        client = @shop.clients.build(user: User.create, external_audience_sources: a['external_audience_sources'], audience_sources: a['audience_sources'])
      end

      client.email = email || client.email
      client.external_id = id if client.external_id.blank? && id.present?

      # Добавляем email в базу к магазину
      shop_email = ShopEmail.fetch(@shop, email, result: true)

      # Добавляем сразу сегмент пользователя
      if segment.present?
        client.add_segment(segment.id)
        shop_email.add_segment(segment.id)
      end

      # Проверяем, что запись новая
      new_record = client.new_record?

      # Сохраняем / создаем
      client.save! if client.changed?
      shop_email.save! if shop_email.changed?

      # Если магазин на Double-Opt In, отправляем письмо
      if new_record && @shop.send_confirmation_email_trigger?
        TriggerMailings::Letter.new(client, TriggerMailings::Triggers::DoubleOptIn.new(client)).send
      end
    end

    # Завершаем обновление сегмента, если был указан
    if segment.present?
      People::Segmentation::SegmentWorker.new.perform(segment)
    end

    # Запускаем перерасчет аудитории
    People::Segmentation::ActivityWorker.new(@shop).update_overall

  rescue Sidekiq::Shutdown => e
    Rollbar.warn e
    sleep 5
    retry
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end
