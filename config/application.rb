require File.expand_path('../boot', __FILE__)

require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

require 'action_dispatch'
require 'logger'

class HandleInvalidPercentEncoding
  DEFAULT_CONTENT_TYPE = 'text/html'
  DEFAULT_CHARSET      = ActionDispatch::Response.default_charset

  attr_reader :logger
  def initialize(app, stdout=STDOUT)
    @app = app
    @logger = defined?(Rails.logger) ? Rails.logger : Logger.new(stdout)
  end

  def call(env)
    begin
      # calling env.dup here prevents bad things from happening
      request = ActionDispatch::Request.new(env.dup)
      # calling request.params is sufficient to trigger the error
      # see https://github.com/rack/rack/issues/337#issuecomment-46453404
      request.params
      @app.call(env)
    rescue ArgumentError => e
      raise unless e.message =~ /invalid %-encoding/
      message = "BAD REQUEST: Returning 400 due to #{e.message} from request with env #{request.inspect}"
      logger.info message
      content_type = request.formats.first || DEFAULT_CONTENT_TYPE
      status = 400
      body   = "Bad Request"
      return [
        status,
        {
           'Content-Type' => "#{content_type}; charset=#{DEFAULT_CHARSET}",
           'Content-Length' => body.bytesize.to_s
        },
        [body]
      ]
    end
  end
end


class SetUnicornProcline
  def initialize(app)
    @app = app
  end

  def call(env)
    user_ip = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR']
    request_info = "#{env['REQUEST_METHOD']} #{env['REQUEST_URI']}"
    worker_line = $0.split(']')[0] + "] #{user_ip}"
    set_procline "#{worker_line}: #{request_info}"[0..200]
    status, headers, body = @app.call(env)
    set_procline "#{worker_line}: last status: #{status}. Waiting for req."
    [status, headers, body]
  end

  def set_procline(value)
    $0 = sanitize_utf8(value)
  end

  def sanitize_utf8(string)
    return string.force_encoding('utf-8') if string.valid_encoding?
    string.chars.select(&:valid_encoding?).join.force_encoding('utf-8')
  end
end

class CatchJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError => error
      if env['CONTENT_TYPE'] =~ /application\/json/i
        error_output = 'There was a problem in the JSON you submitted'
        return [
          400, {'Content-Type' => 'application/json'},
          [ { status: 400, error: error_output }.to_json ]
        ]
      else
        raise error
      end
    end
  end
end


module Rees46Api
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'UTC'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths << Rails.root.join('lib')

    config.generators do |g|
      g.test_framework :rspec
      g.orm :active_record
    end

    config.autoload_paths += ["#{Rails.root}/app/exceptions", "#{Rails.root}/lib"]

    config.secret_key_base = '07bc8d279a1bb8a2836576da1e1020bd88c7'

    config.middleware.use ActionDispatch::Cookies
    config.middleware.insert 0, ::SetUnicornProcline
    config.middleware.insert 0, ::HandleInvalidPercentEncoding
    config.middleware.insert 0, Rack::UTF8Sanitizer
    config.middleware.insert_before ActionDispatch::ParamsParser, ::CatchJsonParseErrors

    config.support_email = 'REES46 <support@rees46.com>'
    config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

    config.active_record.raise_in_transactional_callbacks = true
  end
end
