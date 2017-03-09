class SlackNotifierWorker
  include Sidekiq::Worker

  def perform(username, message, webhook_url: Rails.application.secrets.slack_notify_key)
    notifier = Slack::Notifier.new webhook_url, username: username, http_options: { open_timeout: 3 }
    notifier.ping(message)
  end
end