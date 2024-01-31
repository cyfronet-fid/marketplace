# frozen_string_literal: true

class DesignsystemController < ApplicationController
  layout "designsystem"

  def index
  end

  def show
    render params.require(:file)
  end
end
