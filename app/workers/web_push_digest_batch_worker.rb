##
# Обработчик пачки дайджейстной веб-пущ рассылки.
#
class WebPushDigestBatchWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5, queue: 'mailing'

  attr_accessor :mailing, :current_client, :current_web_push_digest_message

  # Запустить рассылку пачки.
  #
  # @param id [Integer] ID пачки рассылки.
  def perform(id)
    @batch = DigestMailingBatch.find(id)
    @mailing = @batch.mailing
    @shop = Shop.find(@mailing.shop_id)
    @settings = @shop.mailings_settings

    # Не обрабатываем новые пачки, если рассылка ранее дохла.
    if @mailing.failed?
      return
    end

    if @batch.current_processed_client_id.nil?
      @batch.current_processed_client_id = @batch.start_id
    end

    # Проходим по всей доступной аудитории
    relation = @shop.clients.ready_for_web_push_digest.where(id: @batch.current_processed_client_id.value.to_i..@batch.end_id).order(:id)
    relation.each do |client|

      # Каждый раз запоминаем текущий обрабатываемый ID
      @current_client = client
      @batch.update current_processed_client_id: @current_client.id

      @current_web_push_digest_message = @batch.web_push_digest_messages.create!(shop: @shop, client: @current_client, web_push_digest: @mailing).reload

      # Отправляем сообщение
      WebPush::DigestMessage.new(client, @mailing, @batch).send

      # Увеличиваем счетчик отправленных сообщений для прогресса
      @mailing.sent_mails_count.increment

    end
  
    # Отмечаем пачку как завершенную.
    @batch.complete!
  
    # Завершаем рассылку, если все пачки завершены.
    @mailing.finish! if @mailing.batches.incomplete.none?
          
  rescue Sidekiq::Shutdown => e
    Rollbar.error e
    sleep 5
    retry
  rescue => e
    @mailing.fail! if @mailing
    raise e
  end


end
