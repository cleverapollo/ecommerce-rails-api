class Yml
  class NotRespondingError < StandardError; end

  def initialize(shop)
    @shop = shop
  end


  def get
    delete(file_name_xml) if exists?(file_name_xml)
    delete(file_name) if exists?(file_name)
    if responds?
      download
      gzip_archive? ? ungzip : File.rename(file_name, file_name_xml)
      if is_xml?
        yield file
      else
        ErrorsMailer.yml_import_error('goko.gorgiovski@mkechinov.ru', @shop).deliver_now
      end
      delete(file_name_xml)
      delete(file_name)
    else
      raise NotRespondingError
    end
  end

  def gzip_archive?
    File.open(file_name, 'rb').read(2).unpack("S").first == 35615
  end

  def is_xml?
    File.open(file_name_xml, 'rb').read(2).unpack("S").first == 16188 ||
    File.open(file_name_xml, 'rb').read(2).unpack("S").first == 26684 ||
    File.open(file_name_xml, 'rb').read(2).unpack("S").first == 48111
  end

  def responds?
    Curl.responds?(@shop.yml_file_url)
  end

  def file_name_xml
    "#{Rails.root}/tmp/ymls/#{@shop.id}_yml.xml"
  end

  def file_name
    "#{Rails.root}/tmp/ymls/#{@shop.id}_yml"
  end

  def file
    File.open(file_name_xml, 'rb')
  end

  def download
    Curl.download(@shop.yml_file_url, to: file_name)
  end

  def delete(input_file_name)
    File.delete(input_file_name) if exists?(input_file_name)
  end

  def exists?(input_file_name)
    File.exist?(input_file_name)
  end

  def ungzip
    Zlib::GzipReader.open(file_name) do |gz|
      File.open(file_name_xml, "wb") do |g|
        IO.copy_stream(gz, g)
      end
    end
  end
end
