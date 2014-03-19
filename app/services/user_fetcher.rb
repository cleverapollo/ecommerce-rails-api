class UserFetcher
  attr_accessor :uniqid
  attr_accessor :ssid
  attr_accessor :shop_id

  def initialize(opts)
    self.uniqid = opts[:uniqid]
    self.ssid = opts[:ssid]
    self.shop_id = opts[:shop_id]
  end

  def fetch
    session = fetch_session
    master = user_by_session = session.user || session.build_user
    user_by_uniqid = fetch_by_uniqid

    if user_by_uniqid.present? and user_by_session != user_by_uniqid
      UserMerger.merge(user_by_uniqid, user_by_session) if user_by_session.persisted?
      master = user_by_uniqid
    end

    master.save
    session.user = master
    session.save

    link_user_and_shop(master, shop_id)

    return master
  end

  def link_user_and_shop(user, shop_id)
    begin
      ShopsUser.create(user_id: user.id, shop_id: shop_id, ab_testing_group: user.ab_testing_group)
    rescue ActiveRecord::RecordNotUnique => e

    end
  end

  def fetch_session
    Session.find_by(uniqid: ssid) || Session.build_with_uniqid
  end

  def fetch_by_uniqid
    return nil if uniqid.blank?

    if u_s_r = UserShopRelation.find_by(uniqid: uniqid, shop_id: shop_id)
      u_s_r.user
    else
      User.create.tap do |u|
        begin
          UserShopRelation.create(user_id: u.id, shop_id: shop_id, uniqid: uniqid)
        rescue ActiveRecord::RecordNotUnique => e
          # Значит, связь уже создана
          u.destroy
          return UserShopRelation.find_by!(uniqid: uniqid, shop_id: shop_id).user
        end
      end
    end
  end
end
