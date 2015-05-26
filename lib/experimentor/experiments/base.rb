module Experimentor
  module Experiments
    class Base

      include Experimentor::PopulateHelper


      def initialize(params={})
        @params = params
      end

      def populate
        raise NotImplementedError.new('This should be implemented in concrete experiment class')
      end

      def iterate(iteration_params={})
        raise NotImplementedError.new('This should be implemented in concrete experiment class')
      end
    end
  end
end
