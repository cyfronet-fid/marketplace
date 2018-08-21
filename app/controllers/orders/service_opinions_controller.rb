# frozen_string_literal: true

class Orders::ServiceOpinionsController < ApplicationController
  before_action :authenticate_user!

  def new
    @order = Order.find(params[:order_id])
    @service_opinion = ServiceOpinion.new(order: @order)
    authorize(@service_opinion)
  end

  def create
    @order = Order.find(params[:order_id])
    @service = @order.service
    template = service_opinion_template
    authorize(template)

    @service_opinion = ServiceOpinion::Create.new(template).call
    if @service_opinion.persisted?
      redirect_to order_path(@order), notice: "Rating submitted sucessfully"
    else
      render :new, status: :bad_request
    end
  end


  private
    def service_opinion_template
      ServiceOpinion.new(permitted_attributes(ServiceOpinion).merge(order: @order))
    end
end
