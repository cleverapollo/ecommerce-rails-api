require "net/http"
require "open-uri"

class Yml < Struct.new(:path)
  extend Forwardable
  include ActionView::Helpers::NumberHelper

  NotRespondingError = Class.new(StandardError)
  NoXMLFileInArchiveError = Class.new(StandardError)

  def_delegators :io, :read, :readpartial, :rewind, :close

  private

  def io
    @io ||= begin
      file = download
      file = gzip_archive?(file) ? Zlib::GzipReader.new(file.tap(&:rewind)) : file
      fail NoXMLFileInArchiveError unless is_xml?(file)
      file
    end
  end

  def download
    attempts = 10

    begin
      open path, "rb", {
        allow_redirections: :safe,
        progress_proc: ->(bytes) { STDOUT.write "\rDownloaded : #{ number_to_human_size(bytes) }" },
        read_timeout: 10.minutes,
        redirect: true
      }
    rescue Errno::ETIMEDOUT, Net::ReadTimeout, EOFError, Errno::ECONNRESET
      if attempts -= 1
        retry
      else
        raise NotRespondingError.new("Не удаётся выгрузить YML файл в течение 30 минут.")
      end
    rescue OpenURI::HTTPError
      raise NotRespondingError.new("YML файл недоступен.")
    rescue OpenSSL::SSL::SSLError => e
      raise NotRespondingError.new("SSL error: #{e}")
    rescue SocketError
      raise NotRespondingError.new("Некоректный адрес YML файла.")
    end
  end

  def gzip_archive?(file)
    file.tap(&:rewind).read(2).unpack("S").first == 35615
  end

  def is_xml?(file)
    # [16188].pack("S") => "<?"
    # [48111].pack("S") => "\xEF\xBB"
    header = file.tap(&:rewind).read(2).unpack("S").first
    (header == 16188) || (header == 48111)
  end
end
