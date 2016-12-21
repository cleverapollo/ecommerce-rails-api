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
      render json: nil
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
      render json: nil
    end
  end

  # Может поставить на сайт виджет с общей оценкой.
  def reputation_widget
    if @plan.present? && @plan.paid?
      # TODO
      render json: nil
    else
      render json: nil
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


# TODO list:
# Продавец
# Может поставить на сайт виджет с общей оценкой.
