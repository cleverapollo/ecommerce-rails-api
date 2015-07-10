##
# Воркер, импортирующий дополнительную информацию пользователей
# Вызывается со стороны /rees46-rails
#
class UserInfoImportWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

  def perform(params)
    @shop = Shop.find_by!(uniqid: params.fetch('shop_id'), secret: params.fetch('shop_secret'))

    params.fetch('users').each do |a|
      id = a.fetch('id').to_s

      children = a.fetch('children')
      next if id.blank? || children.blank?

      shop_client = shop.clients.find_by(external_id: id)
      if shop_client.blank?
        shop_client = shop.clients.build(external_id: id, user: User.create)
      end

      shop_user = shop_client.user


      shop_user.children = children || shop_user.children

      shop_user.save!
    end
  end
end
