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
    @audiance_count = 0

    params.fetch('audience').each do |a|
      id = a.fetch('id').to_s.strip
      email = IncomingDataTranslator.email(a.fetch('email'))


      next if email.blank?
      id ||= ''

      client = shop.clients.find_by(email: email)

      if client.blank?
        client = shop.clients.find_by(external_id: id)
        if client.present?
          client = shop.clients.build(external_id: '', user: User.create)
        else
          client = shop.clients.build(external_id: id, user: User.create)
        end
      end

      client.email = email || client.email

      # Активируем подписку для импортируемого пользователя
      if client.email.present?
        client.digests_enabled = true
        client.triggers_enabled = true
      end

      client.save!
      @audiance_count += 1
    end

    # Запускаем перерасчет аудитории
    People::Segmentation::ActivityWorker.new(@shop).perform.update

    # CompletesMailer.audiance_import_completed(@shop, @audiance_count).deliver_now if @audiance_count > 0
  end
end
