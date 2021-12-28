# frozen_string_literal: true

class Conversations::MessageBoxComponent < ApplicationComponent
  def initialize(message, message_post_path, message_input_label)
    super()
    @message = message
    @message_post_path = message_post_path
    @message_input_label = message_input_label
  end

  def render?
    if @message.messageable_type == "Project"
      project = @message.messageable
    else
      project = @message.messageable.project
    end

    !project.archived?
  end
end
