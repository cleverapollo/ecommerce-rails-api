class Yml
  class NotRespondingError < StandardError; end

  def initialize(shop)
    @shop = shop
  end

  def get
    delete if exists?
    if responds?
      download
      yield file
      delete
    else
      raise NotRespondingError
    end
  end

  def download
    Curl.download(@shop.yml_file_url, to: file_name)
  end

  def responds?
    Curl.responds?(@shop.yml_file_url)
  end

  def file_name
    "#{Rails.root}/tmp/ymls/#{@shop.id}_yml.xml"
  end

  def file
    File.open(file_name, 'rb')
  end

  def delete
    File.delete(file_name)
  end

  def exists?
    File.exist?(file_name)
  end
end
