module People
  module Segmentation
    class Activity

      A = 1
      B = 2
      C = 3

      attr_accessor :client

      def initialize(client)
        @client = client
      end

      def group_a?
        @client.activity_segment == A
      end

      def group_b?
        @client.activity_segment == B
      end

      def group_c?
        @client.activity_segment == C
      end



    end
  end
end