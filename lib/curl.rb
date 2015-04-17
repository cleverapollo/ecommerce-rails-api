class Curl
  DEFAULT_OPTIONS = '--connect-timeout 60 --max-time 1800'
  class << self
    def download(url, params = {})
      destination = params.fetch(:to)
      `curl #{options} -o #{destination} #{url}`
    end

    def responds?(url)
      `curl #{options} --head #{url}`.include?('200')
    end

    def options
      DEFAULT_OPTIONS
    end
  end
end
