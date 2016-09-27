class WebPush::DigestMessage

  class IncorrectSettingsError < StandardError; end

  attr_accessor :client, :shop, :digest, :batch, :message, :settings, :body, :safari_pusher

  # Инициализиация сообщения
  # @param client [Client]
  # @param digest [WebPushDigest]
  # @param batch [WebPushDigestBatch]
  # @param safari_pusher [Grocer]
  def initialize(client, digest, batch, safari_pusher = nil)
    @client = client
    @shop = @client.shop
    @digest = digest
    @batch = batch
    @safari_pusher = safari_pusher

    @message = client.web_push_digest_messages.create!(
        web_push_digest: digest,
        web_push_digest_batch: batch,
        shop: client.shop,
    ).reload
    @body = generate_body
  end


  # Отправляет уведомление
  def send
    WebPush::Sender.send(client, shop, body, safari_pusher)
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
