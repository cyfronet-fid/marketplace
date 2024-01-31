# frozen_string_literal: true

class Admin::AbTestsController < Admin::ApplicationController
  before_action :authenticate_user!

  def show
  end
end
