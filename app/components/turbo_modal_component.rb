# frozen_string_literal: true

class TurboModalComponent < ApplicationComponent
  include Turbo::FramesHelper

  def initialize(title:)
    super()
    @title = title
  end
end
