##
# Воркер, импортирующий аудиторию дайджестных рассылок.
#
class AudienceImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    @shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    params.fetch('audience').each do |a|
      id = a.fetch('id').to_s
      email = IncomingDataTranslator.email(a.fetch('email'))
      next if id.blank? || email.blank?

      s_u = shop.clients.find_by(external_id: id)
      if s_u.blank?
        s_u = shop.clients.build(external_id: id, user: User.create)
      end

      s_u.email = email || s_u.email

      s_u.save!
    end
  end
end
