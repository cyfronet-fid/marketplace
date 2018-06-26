# frozen_string_literal: true

class Orders::QuestionsController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to order_path(id: params[:order_id])
  end

  def create
    @order = Order.find(params[:order_id])
    @question = Order::Question.
                new(permitted_attributes(Order::Question).
                    merge(author: current_user, order: @order))

    authorize(@question)

    if Order::Question::Create.new(@question).call
      redirect_to order_path(@order)
    else
      render "orders/show"
    end
  end
end
