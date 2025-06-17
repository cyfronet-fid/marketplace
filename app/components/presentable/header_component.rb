# frozen_string_literal: true

class Presentable::HeaderComponent < ApplicationComponent
  include ComparisonsHelper
  include FavouriteHelper
  include PresentableHelper
  include Presentable::HeaderHelper
  include ServiceHelper

  renders_one :buttons

  def initialize(
    object:,
    title:,
    subtitle:,
    comparison_enabled:,
    preview:,
    favourites_enabled: Rails.application.config.whitelabel,
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
    @favourites_enabled = favourites_enabled
    @favourite_services = favourite_services
    @show_checkboxes = show_checkboxes
  end

  def presentable_logo(object, classes = "align-self-center img-fluid", resize = [180, 120])
    super
  end
end
