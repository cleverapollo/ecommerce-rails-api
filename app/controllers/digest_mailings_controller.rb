##
# Контроллер, отвечающий за дайджестные рассылки.
#
class DigestMailingsController < ApplicationController
  include ShopAuthenticator
  before_action :fetch_digest_mailing, only: :launch

  # Запустить рассылку.
  def launch
    if params['test_email'].present?
      Rails.logger.warn "email: #{params['test_email']}, params: #{params.inspect}"
      DigestMailingLaunchWorker.set(queue: 'mailing_test').perform_async(params)
    elsif params['start_at'].present?
      job_id = DigestMailingLaunchWorker.perform_at(DateTime.parse(params['start_at']), params)
      @digest_mailing.update(job_id: job_id) if @digest_mailing.present?
    else
      DigestMailingLaunchWorker.perform_async(params)
    end
    render nothing: true, status: :ok
  end

  def cancel
    @job = Sidekiq::ScheduledSet.new.find_job params['job_id']
    if @job.present? && (is_forced? || can_delete_job?)
      @job.delete
      render nothing: true, status: :ok
    else
      render nothing: true, status: :unprocessable_entity
    end
  end

  private

  def fetch_digest_mailing
    @digest_mailing = @shop.digest_mailings.find_by(id: params.fetch('id'))
  end

  def is_forced?
    params['force'] == 'true'
  end

  def can_delete_job?
    ((Time.at(@job.score) - Time.now) / 1.second).floor > 10
  end

end
