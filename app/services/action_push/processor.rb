module ActionPush
  class Processor
    class << self
      def process(params)
        factory = Action.get_factory(params.action)
        factory.push(params)
      end
    end
  end
end
