module Rees46ML
  class File
    include Enumerable

    def initialize(io, logger = nil)
      @io = io
      @logger = logger || Logger.new(STDOUT).tap{ |l| l.level = Logger::ERROR }
    end

    def each(&black)
      parser = Rees46ML::Parser.new(@logger) { |element| black.call element }
      Ox.sax_parse parser, @io.tap(&:rewind)
    end
  end
end
