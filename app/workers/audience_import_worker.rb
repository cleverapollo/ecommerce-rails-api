##
# Воркер, импортирующий аудиторию дайджестных рассылок.
#
class AudienceImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    @shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    params.fetch('audiences').each do |a|
      if shop.audiences.find_by(email: a.fetch('email')).blank?
        next unless IncomingDataTranslator.email_valid?(a.fetch('email'))

        email = IncomingDataTranslator.email(a.fetch('email'))
      end
    end
  end
end
