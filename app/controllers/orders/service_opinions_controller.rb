# frozen_string_literal: true

class Orders::ServiceOpinionsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_order, only: :create

  def new
    @order = Order.find(params[:order_id])
    @service_opinion = ServiceOpinion.new(order: @order)
    authorize(@service_opinion)
  end

  def create
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
    def find_order
      @order = Order.joins(:service).find(params[:order_id])
    end

    def service_opinion_template
      ServiceOpinion.new(permitted_attributes(ServiceOpinion).merge(order: @order))
    end
end
