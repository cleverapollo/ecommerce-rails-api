module Media
  class RecommenderService
    def self.recommendations(params)
      socket = if Rails.env.development?
        UNIXSocket.new("/home/maroki/reess46/junixsocket-test.sock")
      elsif Rails.env.production?
        UNIXSocket.new("/home/rails/rees46_content_recommender/socket_file.sock")
      end

      line = ""
      socket.puts(params.to_json)

      status = Timeout::timeout(2) {
        line = socket.gets
      }

      JSON.parse(line).values
    end
  end
end
