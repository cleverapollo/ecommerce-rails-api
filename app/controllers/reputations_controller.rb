class ReputationsController < ApplicationController
  include ShopFetcher
  before_action :fetch_non_restricted_shop
  before_action :fetch_item, only: [:item_reputation]
  before_action :fetch_subscription_plans
  before_action :set_count_and_offset, only: [:shop_reputation, :item_reputation]

  # Oпубликованых отзывов с оценками к магазину.
  # get param shop_id (*) - (uniqid - магазина)
  # get param count       - (The number of records to return.)
  # get param offset     - (The number of records from a collection to skip. "count*offset")
  # route: /reputation/shop
  def shop_reputation
    @shop.subscription_plans.reputation

    if @plan.present? && @plan.paid?
      render json: @shop.reputations.for_shop.published.select(:id, 'name AS client', :rating, 'plus AS pros', 'minus AS cons', :comment).order(id: :desc).limit(@count).offset(@offset)
    else
      render json: {}
    end
  end

  # Oпубликованых отзывов с оценками к товару
  # get param shop_id    (*) - (uniqid - магазина)
  # get param product_id (*) - (uniqid - товара)
  # get param count          - (The number of records to return.)
  # get param offset         - (The number of records from a collection to skip. "count*offset")
  # route: /reputation/product
  def item_reputation
    if @plan.present? && @plan.paid?
      render json: @item.reputations.published.select(:id, 'name AS client', :rating, 'plus AS pros', 'minus AS cons', :comment).order(id: :desc).limit(@count).offset(@offset)
    else
      render json: {}
    end
  end

  # Может поставить на сайт виджет с общей оценкой.
  def reputation_widget
    if @plan.present? && @plan.paid?
      review = @shop.reputations.published.for_shop.actual.where('comment IS NOT NULL AND rating > 2').order('RANDOM()').first
      render text: '' and return if review.blank?

      rate = @shop.reputations.published.for_shop.actual.average(:rating).to_f.round(1)
      widget = File.read("app/assets/snippets/reputation/#{@shop.customer.language}/widget.html")
      widget.gsub!('{{ style }}', params[:style] || 'white')
      widget.gsub!('{{ reputaion_url }}', "#{Rees46.site_url}/shops/#{@shop.uniqid}/reputations")
      widget.gsub!('{{ rate_percent }}', (rate * 20).to_i.to_s)
      widget.gsub!('{{ rate }}', rate.to_s)
      widget.gsub!('{{ review }}', review.comment.truncate(70))
      widget.gsub!('{{ name }}', review.name)
      widget.gsub!('{{ date }}', review.created_at.to_s)

      render text: widget
    else
      render text: ''
    end
  end

  private

  def fetch_subscription_plans
    @plan = @shop.subscription_plans.reputation.first
  end

  def fetch_item
    @item = @shop.items.find_by(uniqid: params[:product_id])
    if @item.blank?
      render(nothing: true) and return false
    end
  end

  def set_count_and_offset
    @count = params[:count].present? && params[:count].to_i > 0 && params[:count].to_i < 51 ? params[:count].to_i : 50
    @offset = params[:offset].present? && params[:offset].to_i > 0 ? @count * params[:offset].to_i : 0
  end
end
