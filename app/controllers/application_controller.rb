# frozen_string_literal: true

require "turbolinks"

class ApplicationController < ActionController::Base
  include Turbolinks::Redirection
  include Sentryable
  include Pundit

  protect_from_forgery
end
