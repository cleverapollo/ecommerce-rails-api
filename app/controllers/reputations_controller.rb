class ReputationsController < ApplicationController
  include ShopFetcher
  before_action :fetch_non_restricted_shop
  before_action :fetch_item, only: [:item_reputation]
  before_action :fetch_subscription_plans

  # Последные 30 опубликованых отзывов с оценками к магазину.
  # get param shop_id - (uniqid - магазина)
  # route: /reputation/shop
  def shop_reputation
    @shop.subscription_plans.reputation

    if @plan.present? && @plan.paid?
      render json: @shop.reputations.for_shop.published.select(:id, 'name AS client', :rating, 'plus AS pros', 'minus AS cons', :comment).order(id: :desc).limit(30)
    else
      render json: nil
    end
  end

  # Последные 30 опубликованых отзывов с оценками к товару
  # get param shop_id    - (uniqid - магазина)
  # get param product_id - (uniqid - товара)
  # route: /reputation/product
  def item_reputation
    if @plan.present? && @plan.paid?
      render json: @item.reputations.published.select(:id, 'name AS client', :rating, 'plus AS pros', 'minus AS cons', :comment).order(id: :desc).limit(30)
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

end


# TODO list:
# Продавец
# Может поставить на сайт виджет с общей оценкой.
