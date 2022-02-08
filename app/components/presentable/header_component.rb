# frozen_string_literal: true

class Presentable::HeaderComponent < ApplicationComponent
  include ApplicationHelper
  include Presentable::HeaderHelper
  include ServiceHelper
  include ComparisonsHelper
  include FavouriteHelper

  def initialize(
    object:,
    title:,
    subtitle:,
    comparison_enabled:,
    preview:,
    question:,
    favourite_services: [],
    orderable: false,
    show_manage_button: false
  )
    super()
    @object = object
    @title = title
    @subtitle = subtitle
    @comparison_enabled = comparison_enabled
    @preview = preview
    @question = question
    @favourite_services = favourite_services
    @orderable = orderable
    @show_manage_button = show_manage_button
  end

  def object_logo(object, classes = "align-self-center img-fluid", resize = "180x120")
    super
  end

  def new_question_link
    @object.instance_of?(Service) ? new_service_question_path(@object) : new_provider_question_path(@object)
  end

  def new_question_prompt
    @object.instance_of?(Service) ? "Ask a question about this resource?" : "Ask this provider a question"
  end
end
