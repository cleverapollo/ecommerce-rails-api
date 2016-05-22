module TriggerMailings
  class OptivoMytoysLetter < TriggerMailings::Letter

    attr_accessor :api

    class << self

      # Выгружает триггеры в Optivo и удаляет устаревшие данные
      def sync
        mails = TriggerMailingQueue.where('triggered_at <= ?', Time.current)
        # ... transfer it to FTP
        mails.delete_all
        raise NotImplementedError.new('This should be implemented before production')
        true
      end

    end


    def initialize(client, trigger)
      @client = client
      @shop = @client.shop
      @trigger = trigger
      @trigger_mail = client.trigger_mails.create!(
          mailing: trigger.mailing,
          shop: client.shop,
          trigger_data: {
              trigger: trigger.to_json
          }
      ).reload
    end

    # Сохраняем в базу триггер
    def send
      data = {
        triggered_at: Time.now,
        user_id: @client.user_id,
        shop_id: @shop.id,
        trigger_type: @trigger.code.underscore,
        recommended_items: @trigger.recommended_ids(8),
        source_items: [],
        email: client.email,
        trigger_mail_code: @trigger_mail.code
      }

      if @trigger.source_items.present? && @trigger.source_items.is_a?(Array)
        data[:source_items] = @trigger.source_items.map(&:uniqid)
      end

      TriggerMailingQueue.create! data
    end


  end
end
