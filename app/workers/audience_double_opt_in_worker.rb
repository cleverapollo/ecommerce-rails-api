##
# Воркер, импортирующий аудиторию дайджестных рассылок.
# Вызывается со стороны /rees46-rails
#
class AudienceDoubleOptInWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_accessor :shop

  def perform(params)
    @shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    # Если включен double opt in у магазина
    if @shop.send_confirmation_email_trigger?

      # Находим всю аудиторию магазина, не подтвердивших email
      @shop.clients.with_email.where(email_confirmed: nil).find_each do |client|
        TriggerMailings::Letter.new(client, TriggerMailings::Triggers::DoubleOptIn.new(client)).send
      end

      # Запускаем перерасчет аудитории
      People::Segmentation::ActivityWorker.new(@shop).update_overall
    end
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end
end
