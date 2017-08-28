class Actions::Tracker

  # @return [ActionPush::Params]
  attr_accessor :params

  # @param [ActionPush::Params] params
  def initialize(params)
    self.params = params
  end

  # @param [Item] object
  def track(object)
    case object
      when Item
        track_object(object.class, object.uniqid)
    end
  end

  private

  # todo тестируем вставку в Clickhouse
  # @param [String] type
  # @param [String] id
  def track_object(type, id)
    begin
      query = "INSERT INTO rees46.actions (session_id, current_session_code, shop_id, event, object_type, object_id, recommended_by, recommended_code, referer, useragent)
                 VALUES (#{params.session.id}, '#{params.current_session_code}', #{params.shop.id}, '#{params.action}', '#{type}', '#{id}',
                         #{params.recommended_by ? "'#{params.recommended_by}'" : 'NULL'},
                         #{params.source.present? && params.source['code'].present? ? "'#{params.source['code']}'" : 'NULL'},
                         '#{params.request.referer}', '#{params.request.user_agent}')"
      if Rails.env.production?
        Thread.new { HTTParty.post("http://#{ Rails.application.secrets.clickhouse_host}:8123",body: query) }
      else
        Rails.logger.debug "ClickHouse: #{query}"
      end
    rescue StandardError => e
      Rollbar.error 'Clickhouse action insert error', e
    end
  end
end
