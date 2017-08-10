##
# Обработчик поискового запроса
#
module SearchEngine
  class Processor
    class << self
      def process(params)
        implementation = SearchEngine::Base.get_implementation_for(params.type)
        implementation.new(params).recommendations
      end
    end
  end
end
