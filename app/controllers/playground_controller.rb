# frozen_string_literal: true

class PlaygroundController < ApplicationController
  before_action :authenticate_user!

  def show
    @file = params.require(:file)

    render @file
  end
end
