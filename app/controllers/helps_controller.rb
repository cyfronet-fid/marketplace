# frozen_string_literal: true

class HelpsController < ApplicationController
  before_action :ensure_admin

  def show
    @sections = HelpSection.includes(:help_items)
  end

  private
    def ensure_admin
      redirect_to page_path("help") unless current_user&.admin?
    end
end
