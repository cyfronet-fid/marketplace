# frozen_string_literal: true

class CartsController < ApplicationController
  def create
    session[:order_item] = params[:order]
    redirect_to new_order_path
  end
end
