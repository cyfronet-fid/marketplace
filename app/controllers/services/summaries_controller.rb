# frozen_string_literal: true

class Services::SummariesController < Services::ApplicationController
  def show
  end

  def create
    # TODO create order
    render :confirmation, layout: "ordered"
  end
end
