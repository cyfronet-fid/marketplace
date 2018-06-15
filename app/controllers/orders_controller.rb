# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = policy_scope(Order)
  end

  def show
    @order = Order.joins(:user, :service).find(params[:id])
    authorize(@order)
  end

  def create
    order = Order.new(permitted_attributes(Order).merge(user: current_user))
    authorize(order)

    if order.save
      redirect_to order_path(order)
    else
      redirect_to service_path(order.service),
                  alert: "Unable to create order"
    end
  end
end
