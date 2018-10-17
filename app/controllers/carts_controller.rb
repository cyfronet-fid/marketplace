# frozen_string_literal: true

class CartsController < ApplicationController
  def create
    session[:project_item_item] = params[:project_item]
    redirect_to new_project_item_path
  end
end
