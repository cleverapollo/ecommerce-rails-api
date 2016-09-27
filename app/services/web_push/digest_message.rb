class WebPush::DigestMessage

  class IncorrectSettingsError < StandardError; end

  attr_accessor :client, :shop, :digest, :batch, :message, :settings, :body

  def initialize(client, digest, batch)
    @client = client
    @shop = @client.shop
    @digest = digest
    @batch = batch

    @message = client.web_push_digest_messages.create!(
        web_push_digest: digest,
        web_push_digest_batch: batch,
        shop: client.shop,
    ).reload
    @body = generate_body
  end


  # Отправляет уведомление
  def send
    WebPush::Sender.send client, shop, body
  end

  private

  # Создает JSON-объект для отправки web push сообщения
  # @return JSON
  def generate_body
    JSON.generate({
        title:  digest.subject,
        body:   digest.message,
        icon:   digest.fetch_picture_url,
        url:    UrlParamsHelper.add_params_to(digest.url, {
            utm_source: 'rees46',
            utm_medium: 'web_push_digest',
            utm_campaign: "rees46_web_push_#{digest.id}",
            recommended_by: 'web_push_digest',
            rees46_web_push_digest_code: message.code
        })
    })
  end
end
