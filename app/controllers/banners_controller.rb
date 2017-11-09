class BannersController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop

  def get

    # Ищем инвентарь магазина
    # @type [ShopInventory] shop_inventory
    shop_inventory = @shop.shop_inventories.banner.find(params[:id])
    shop_inventory_banners = shop_inventory.shop_inventory_banners
    banners = []

    # Достаем всех вендоров для инвенторя
    vendor_campaigns = shop_inventory.vendor_campaigns

    # Конвертируем цену вендора в цену инвенторя
    vendor_campaigns.each do |vendor|
      vendor.max_cpc_price = vendor.currency.recalculate_to(shop_inventory.currency, vendor.max_cpc_price)
    end

    # Сортируем кампании по убыванию стоимости клика
    vendor_campaigns = vendor_campaigns.sort_by {|_key, v| _key.max_cpc_price}.reverse

    # Проходим по списку баннеров
    shop_inventory_banners.each do |shop_inventory_banner|

      # Изначально вставляем баннер магазина
      banner = {inventory: shop_inventory_banner.id, image: "#{Rees46.site_url}#{shop_inventory_banner.image.url}", url: shop_inventory_banner.url, position: shop_inventory_banner.position}

      # Пробуем найти вендора подходящего под ставку
      vendor_campaign = vendor_campaigns.select { |v| v.max_cpc_price >= shop_inventory_banner.ratio * shop_inventory.min_cpc_price.to_f }.first
      if vendor_campaign.present?

        # Используем баннер вендора
        banner = {id: vendor_campaign.id, inventory: vendor_campaign.shop_inventory_id, image: "#{Rees46.vendor_url}#{vendor_campaign.image.url}", url: vendor_campaign.url, position: shop_inventory_banner.position}

        # Удаляем вендора из списка
        vendor_campaigns.reject! {|v| v.id == vendor_campaign.id }
      end

      # Добавляем в общий список
      banners << banner
    end

    render json: { settings: { width: shop_inventory.image_width, height: shop_inventory.image_height, timeout: (shop_inventory.settings['timeout'] || 5).to_i }, banners: banners }
  end
end
