# frozen_string_literal: true

class Presentable::HeaderComponent < ApplicationComponent
  include PresentableHelper
  include Presentable::HeaderHelper
  include ServiceHelper
  include ComparisonsHelper
  include FavouriteHelper

  renders_one :buttons

  def initialize(
    object:,
    title:,
    subtitle:,
    comparison_enabled:,
    preview:,
    question:,
    favourite_services: [],
    abbreviation: nil,
    show_checkboxes: true
  )
    super()
    @object = object
    @title = title
    @abbreviation = abbreviation
    @subtitle = subtitle
    @comparison_enabled = comparison_enabled
    @preview = preview
    @question = question
    @favourite_services = favourite_services
    @show_checkboxes = show_checkboxes
  end

  def presentable_logo(object, classes = "align-self-center img-fluid", resize = "180x120")
    super
  end

  def new_question_link
    @object.instance_of?(Provider) ? new_provider_question_path(@object) : new_service_question_path(@object)
  end

  def new_question_prompt
    @object.instance_of?(Provider) ? "Ask this provider a question" : "Ask a question about this service?"
  end
end
