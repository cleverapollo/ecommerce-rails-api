##
# Воркер, импортирующий аудиторию дайджестных рассылок.
#
class AudienceImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    params.fetch('audiences').each do |a|
      audience = shop.audiences.find_or_initialize_by(external_id: a.fetch('id').to_s)
      audience.update!(
        email: a.fetch('email'),
        active: a['active'] || true,
        custom_attributes: a.except('id', 'email', 'active'))
    end
  end
end
