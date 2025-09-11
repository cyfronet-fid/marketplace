# frozen_string_literal: true

class Services::InlineOrderUrlComponent < ApplicationComponent
  def initialize(offerable:, classes: "btn btn-outline-primary mt-3")
    super()
    @offerable = offerable
    @classes = classes
  end

  def call
    link_to link_name, url, class: @classes, target: "_blank", title: "External link", "data-probe": ""
  end

  def url
    # Get URL directly from offer - prefer order_url, fallback to service webpage_url
    return @offerable.order_url unless @offerable.order_url.blank?

    service = @offerable.service || @offerable.deployable_service
    service&.webpage_url
  end

  def link_name
    @offerable.external? ? _("Go to the order website") : _("Go to the service")
  end

  def render?
    url.present? && !@offerable.orderable?
  end
end
