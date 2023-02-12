# frozen_string_literal: true

class Services::InlineOrderUrlComponent < ApplicationComponent
  include ProjectItemsHelper

  def initialize(offerable:, classes: "btn btn-outline-primary mt-3")
    super()
    @offerable = offerable
    @classes = classes
  end

  def call
    link_to link_name, url, class: @classes, target: "_blank", title: "External link", "data-probe": ""
  end

  def url
    webpage(@offerable)
  end

  def link_name
    @offerable.external? ? _("Go to the order website") : _("Go to the service")
  end

  def render?
    url.present? && !@offerable.orderable?
  end
end
