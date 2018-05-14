# frozen_string_literal: true

require "turbolinks"

class ApplicationController < ActionController::Base
  include Turbolinks::Redirection
end
