# frozen_string_literal: true

class TurboModalComponent < ApplicationComponent
  include ApplicationHelper
  include Turbo::FramesHelper

  def initialize(title:, custom_style: nil)
    super()
    @title = title
    @custom_style = custom_style
  end
end
