module People
  module Segmentation
    class MailingsWorker

      attr_accessor :shop

      def initialize(shop)
        @shop = shop
      end

      def perform
        stat = AudienceSegmentStatistic.fetch(@shop)

      end

    end
  end
end