# frozen_string_literal: true

class CartsController < ApplicationController
  before_action :authenticate_user!, except: :create

  def show
    if !session[:order_item].blank?
      @cart = Service.find(session[:order_item]["service_id"])
    end
  end

  def create
    session[:order_item] = params[:order]
    redirect_to(action: :show)
  end
end
