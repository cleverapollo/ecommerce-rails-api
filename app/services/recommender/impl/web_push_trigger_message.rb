module Recommender
  module Impl
    ##
    # Псевдокласс-рекомендер. Нужен для трекинга покупок с веб пушей.
    # Дублирует web_push_digest, потому что пока непонятно, что здесь используется rees46_api/app/models/order.rb:47
    #
    class WebPushTriggerMessage < Recommender::Raw
      def recommended_ids
        raise NotImplementedError
      end
    end
  end
end
