class Yml
  class NotRespondingError < StandardError; end

  def initialize(shop)
    @shop = shop
  end

  def get
    delete(file_name) if exists?(file_name)
    delete(file_name_gz) if exists?(file_name_gz)
    if responds?
      if MIME::Types.type_for(@shop.yml_file_url).first.content_type == 'application/x-gzip'
        download(file_name_gz)
        ungzip
        yield file
        delete(file_name)
        delete(file_name_gz)
      else
        download(file_name)
        yield file
        delete(file_name)
      end
    else
      raise NotRespondingError
    end
  end

  def responds?
    Curl.responds?(@shop.yml_file_url)
  end

  def file_name
    "#{Rails.root}/tmp/ymls/#{@shop.id}_yml.xml"
  end

  def file_name_gz
    "#{Rails.root}/tmp/ymls/#{@shop.id}_yml.xml.gz"
  end

  def file
    File.open(file_name, 'rb')
  end

  def download(input_file_name)
    Curl.download(@shop.yml_file_url, to: input_file_name)
  end

  def delete(input_file_name)
    File.delete(input_file_name) if exists?(input_file_name)
  end

  def exists?(input_file_name)
    File.exist?(input_file_name)
  end

  def ungzip
    Zlib::GzipReader.open(file_name_gz) do |gz|
      binding.pry if Rails.env.development?
      File.open(file_name, "wb") do |g|
        IO.copy_stream(gz, g)
      end
    end
  end
end
