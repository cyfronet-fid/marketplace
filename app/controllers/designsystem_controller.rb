# frozen_string_literal: true

class DesignsystemController < ApplicationController
  layout "designsystem"

  ALLOWED_FILES =
    Dir
      .glob(Rails.root.join("app/views/designsystem/*.html.haml"))
      .map { |path| File.basename(path, ".html.haml") }
      .freeze

  def index
  end

  def show
    file = params.require(:file)
    raise ActionController::RoutingError, "Not Found" unless ALLOWED_FILES.include?(file)

    render file
  end
end
