# frozen_string_literal: true

class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = policy_scope(Order)
  end

  def show
    @order = Order.joins(:user, :service).find(params[:id])

    authorize(@order)

    @question = Order::Question.new(order: @order)
  end

  def new
    @order = Order.new(service: selected_service)
    authorize(@order)
  end

  def create
    delete_order_from_session

    authorize(order_template)
    order = Order::Create.new(order_template).call

    if order.persisted?
      redirect_to order_path(order)
    else
      redirect_to service_path(order.service),
                  alert: "Unable to create order"
    end
  end

  private

    def order_template
      @new_order ||= Order.new(permitted_attributes(Order).
                               merge(user: current_user))
    end

    def delete_order_from_session
      session.delete(:order_item)
    end

    def selected_service
      @selected_service ||=
        Service.find_by(id: session[:order_item]["service_id"])
    end
end
