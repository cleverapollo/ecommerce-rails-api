require "net/http"
require "open-uri"

class Yml < Struct.new(:path, :locale)
  extend Forwardable
  include ActionView::Helpers::NumberHelper

  NotRespondingError = Class.new(StandardError)
  NoXMLFileInArchiveError = Class.new(StandardError)
  NotXMLFile = Class.new(StandardError)

  def_delegators :io, :read, :readpartial, :rewind, :close

  private

  def io
    @io ||= begin
      file = download

      if file.nil?
        fail NotRespondingError.new(I18n.t('yml_errors.unavailable_file'))
      end

      if gzip_archive?(file)
        file = Zlib::GzipReader.new(file.tap(&:rewind))
        fail NoXMLFileInArchiveError unless is_xml?(file)
      else
        fail NotXMLFile.new(I18n.t('yml_errors.no_xml_file')) unless is_xml?(file)
      end

      fail NoXMLFileInArchiveError unless is_xml?(file)

      # # @DEBUG 828
      # begin
      #   FileUtils.cp file.path, "#{Rails.root}/tmp/ymls/#{Time.current.to_s}.xml"
      # rescue
      #   Rollbar.error 'Cant save temporary YML file'
      # end

      file
    end
  end

  def download
    attempts = 10
    I18n.locale = locale

    begin
      open path, "rb", {
        allow_redirections: :safe,
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
        'Accept-Encoding' => '',
        progress_proc: ->(bytes) { STDOUT.write "\rDownloaded : #{ number_to_human_size(bytes) }" },
        read_timeout: 10.minutes,
        redirect: true
      }
    rescue Errno::ETIMEDOUT, Net::ReadTimeout, EOFError, Errno::ECONNRESET
      attempts -= 1
      if attempts > 0
        retry
      else
        raise NotRespondingError.new(I18n.t('yml_errors.time_limit_exceeded'))
      end
    rescue OpenURI::HTTPError
      raise NotRespondingError.new(I18n.t('yml_errors.unavailable_file'))
    rescue OpenSSL::SSL::SSLError => e
      raise NotRespondingError.new("SSL error: #{e}")
    rescue SocketError
      raise NotRespondingError.new(I18n.t('yml_errors.wrong_url'))
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
