# frozen_string_literal: true

class Services::InlineOrderTypeComponent < ApplicationComponent
  TOOLTIP = {
    order_required:
      _("Identity of a user is required." + "\nAccess has to be granted manually after analysis of the request."),
    open_access: _("Service is open to everyone, no login required."),
    fully_open_access: _("Service is open to everyone, no login required."),
    other: _("Service has other order type, visit its website to know the details."),
    various: _("Service has various order types, check offers to know the details."),
    external:
      _(
        "Service orders are handled externally," \
          "\nbut access requests coming from EOSC-hub can be tracked" \
          "\nand reflected in the Management Back Office."
      )
  }.freeze

  TITLE = {
    order_required: _("Order Required"),
    open_access: _("Open Access"),
    fully_open_access: _("Fully Open Access"),
    other: _("Other"),
    various: _("Various"),
    external: _("External")
  }.freeze

  def initialize(tag, order_type)
    super()
    @tag = tag
    @order_type = order_type
  end

  def call
    content_tag(
      @tag.to_sym,
      TITLE[@order_type.to_sym],
      { "data-toggle": "tooltip", title: TOOLTIP[@order_type.to_sym] }
    )
  end
end
