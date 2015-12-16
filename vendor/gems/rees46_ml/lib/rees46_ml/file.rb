require "forwardable"

module Rees46ML
  class File
    include Enumerable
    extend Forwardable

    def initialize(io, logger = nil)
      @io = io
      @logger = logger || Logger.new(STDOUT).tap{ |l| l.level = Logger::ERROR }
    end

    def_delegator :enumerator, :each

    def shop
      lazy.detect{ |element| element.is_a? Rees46ML::Shop }
    end

    def offers
      lazy.select{ |element| element.is_a? Rees46ML::Offer }
    end

    private

    def enumerator
      Enumerator.new do |enum|
        parser = Fiber.new do
          handler = Rees46ML::Parser.new(@logger) { |element| Fiber.yield element }
          Nokogiri::XML::SAX::Parser.new(handler).parse(@io.tap(&:rewind))
        end

        while element = parser.resume
          enum << element
        end
      end
    end
  end
end
