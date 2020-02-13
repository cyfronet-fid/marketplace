# frozen_string_literal: true

class HelpsController < ApplicationController
  def show
    @sections = policy_scope(HelpSection).includes(:help_items).order(:position)
  end
end
