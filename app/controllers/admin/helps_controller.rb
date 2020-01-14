# frozen_string_literal: true

class Admin::HelpsController < Admin::ApplicationController
  def show
    @sections = HelpSection.includes(:help_items).all
  end
end
