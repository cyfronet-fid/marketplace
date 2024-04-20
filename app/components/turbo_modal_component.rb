# frozen_string_literal: true

class TurboModalComponent < ApplicationComponent
  include ApplicationHelper
  include Turbo::FramesHelper

  def initialize(title:)
    super()
    @title = title
  end
end
