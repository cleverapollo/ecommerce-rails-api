require "archive"
require "net/http"
require "open-uri"

class Yml
  class NotRespondingError < StandardError; end
  class NoXMLFileInArchiveError < StandardError; end

  def initialize(shop)
    @shop = shop
  end

  def get
    download do |io|
      if is_xml? io
        yield io.tap(&:rewind)
      else
        raise NoXMLFileInArchiveError
      end
    end
  end

  private

  def gzip_archive?(io)
    io.tap(&:rewind).read(2).unpack("S").first == 35615
  end

  def is_xml?(io)
    # [16188].pack("S") => "<?"
    # [48111].pack("S") => "\xEF\xBB"
    header = io.tap(&:rewind).read(2).unpack("S").first
    (header == 16188) || (header == 48111)
  end

  def download
    open @shop.yml_file_url, "rb" do |io|
      if gzip_archive? io.tap(&:rewind)
        Zlib::GzipReader.open(io) { |ungziped| yield ungziped }
      else
        yield io
      end
    end
  end
end
