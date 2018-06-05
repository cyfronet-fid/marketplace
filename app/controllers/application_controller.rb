# frozen_string_literal: true

require "turbolinks"

class ApplicationController < ActionController::Base
  include Turbolinks::Redirection

  private

    def authenticate_user!
      render file: "public/401", status: :unauthorized, layout: false unless current_user
    end
end
