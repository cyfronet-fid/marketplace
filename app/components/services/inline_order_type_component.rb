# frozen_string_literal: true

class Services::InlineOrderTypeComponent < ApplicationComponent
  TOOLTIP = {
      order_required: _("Identity of a user is required." +
          "\nAccess has to be granted manually after analysis of the request."),
      open_access: _("Resource is open to everyone, no login required."),
      fully_open_access: _("Resource is open to everyone, no login required."),
      other: _("Resource has other order type, visit its website to know the details."),
      various: _("Resource has various order types, check offers to know the details."),
      external: _("Resource orders are handled externally," +
          "\nbut access requests coming from EOSC-hub can be tracked" +
          "\nand reflected in the Management Back Office.")
  }

  TITLE = {
      order_required: _("Order Required"),
      open_access: _("Open Access"),
      fully_open_access: _("Fully Open Access"),
      other: _("Other"),
      various: _("Various"),
      external: _("External")
  }

  def initialize(tag, order_type)
    @tag = tag
    @order_type = order_type
  end

  def call
    content_tag(@tag.to_sym, TITLE[@order_type.to_sym], { "data-toggle": "tootltip",
        "title": TOOLTIP[@order_type.to_sym] })
  end
end
