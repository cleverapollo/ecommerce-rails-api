class RtbImpressionsController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop

  # Создать баннерный показ по идентификатору задачи
  def create
    rtb_job = RtbJob.find(params[:rtb_job_id])
    rtb_impression = RtbImpression.create! code: "popunder-#{rand}-#{Time.now.to_i}", bid_id: "random-stub-#{rand}-#{Time.now.to_i}", ad_id: rtb_job.id, price: '1.5', currency: 'rub', shop_id: @shop.id, item_id: rtb_job.item_id, user_id: rtb_job.user_id, date: Time.current
    render json: {code: rtb_impression.code}
  rescue ActiveRecord::RecordNotFound => e
    respond_with_not_found_error('Ad not found')
    Rollbar.warn('Incorrect popunder ad id', e, params)
  end

end
