##
# Контроллер, обрабатывающий отрисовку блоков рекомендаций для внешних сервисов триггерных рассылок
# TODO: отрефакторить все нахрен.
#
class TriggersController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop
  before_action :fetch_trigger_mail


  # Найти клиента. Если нет, ничего не возвращать.
  # Найти рассылку. Если нет, ничего не возвращать.
  def trigger_content

    if !@trigger_mail
      render nothing: true
      return
    end

    client = @trigger_mail.client

    trigger_data = JSON.parse(@trigger_mail.trigger_data['trigger'])

    source_item = fetch_source_item trigger_data

    if !source_item
      render nothing: true
      return
    end

    item = Item.find source_item['id']
    data = item_for_letter item, client.location, @trigger_mail

    render inline: <<-HTML
      <table style="width: 100%; border: 0;">
        <tr style="font: normal 16px/24px Arial, Verdana, sans-serif; color: #ff6600;">
          <td align="center" style="text-align: center;">
          <a href="#{data[:url]}" title="#{data[:name]}" target="_blank"><img src="#{data[:image_url]}" style="display: block; margin: auto; padding: 0px; max-width: 220px; height: auto; max-height: 220px; text-align: center;" border="0"></a>
          <a style="text-align: left; width: 220px; display: block; margin: 0 auto; font: normal 16px/24px Arial, Verdana, sans-serif; color: #ff6600;" href="#{data[:url]}" target="_blank">#{data[:name]}</a>
          <span style="display: block; width: 220px; margin: 0 auto; text-align: left; font: normal 24px/30px Arial, Verdana, sans-serif; color: #000000;">#{data[:price]} #{data[:currency]}</span>
          </td>
        </tr>
      </table>
    HTML

  end


  # Найти клиента. Если нет, то использовать дефолтного.
  # Найти рассылку. Если нет, ничего не возвращать.
  def additional_content

    if !@trigger_mail
      render nothing: true
      return
    end

    trigger_data = JSON.parse(@trigger_mail.trigger_data['trigger'])

    source_item = fetch_source_item trigger_data

    unless source_item
      render nothing: true
      return
    end

    client = @trigger_mail.client

    trigger = "TriggerMailings::Triggers::#{@trigger_mail.mailing.trigger_type.camelize}".constantize.new client
    case @trigger_mail.mailing.trigger_type
      when 'abandoned_cart'
        trigger.source_item = source_item
      when 'viewed_but_not_bought'
        trigger.source_item = source_item
      when 'recently_purchased'
        trigger.source_item = source_item
    end
    recommendations = trigger.recommendations 9

    final_html = <<-HTML
      <table style="width: 100%; border: 0">
    HTML

    recommendations.each_with_index do |item, index|
      if index == 0
        final_html += <<-HTML
        <tr>
        HTML
      elsif index % 3 == 0
        final_html += <<-HTML
          </tr><tr>
        HTML
      end
      data = item_for_letter item, client.location, @trigger_mail
      final_html += <<-HTML
        <td align="center" style="text-align: center;">
          <a href="#{data[:url]}" title="#{data[:name]}" target="_blank" style="display: block; height: 220px;"><img src="#{data[:image_url]}" style="display: block; margin: auto; padding: 0px; max-width: 220px; height: auto; max-height: 220px; text-align: center;" border="0"></a>
          <a style="text-align: left; width: 220px; display: block; margin: 0 auto; font: normal 16px/24px Arial, Verdana, sans-serif; color: #ff6600;" href="#{data[:url]}" target="_blank">#{data[:name]}</a>
          <span style="display: block; width: 220px; margin: 0 auto; text-align: left; font: normal 24px/30px Arial, Verdana, sans-serif; color: #000000;">#{data[:price]} #{data[:currency]}</span>
        </td>
      HTML
    end
    if recommendations.count > 0
      final_html += <<-HTML
        </tr>
      HTML
    end

    final_html += <<-HTML
      </table>
    HTML

    render inline: final_html

  end



  private

  def fetch_trigger_mail
    @trigger_mail = TriggerMail.find_by(code: params[:rees46_trigger_mail_code])
  end

  def fetch_source_item(trigger_data)
    source_item = nil
    if trigger_data['source_items'].present?
      source_items = JSON.parse trigger_data['source_items']
      if source_items.any?
        Rollbar.warning('GetResponse trigger with few source items', @trigger_mail)
        source_item = source_items.first
      end
    elsif trigger_data['source_item'].present?
      source_item = JSON.parse trigger_data['source_item']
    end
    if source_item
      return Item.find source_item['id']
    else
      return nil
    end
  end


  # Обертка над товаром для отображения в письме
  # @param [Item] товар
  #
  # @raise [Mailings::NotWidgetableItemError] исключение, если у товара нет необходимых параметров
  # @return [Hash] обертка
  def item_for_letter(item, location, trigger_mail)
    raise Mailings::NotWidgetableItemError.new(item) unless item.widgetable?
    {
        name: item.name.truncate(40),
        description: item.description.to_s.truncate(130),
        price: ActiveSupport::NumberHelper.number_to_rounded(item.price_at_location(location), precision: 0, delimiter: ' '),
        url: UrlParamsHelper.add_params_to(item.url, Mailings::Composer.utm_params(trigger_mail)),
        image_url: item.image_url,
        currency: item.shop.currency
    }
  end

end
