# frozen_string_literal: true

class Filter::Status < Filter
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "state",
      type: :select,
      title: "Service status",
      index: "status"
    )
  end

  private

  def fetch_options
    [{ name: "Any", id: nil }] +
      Service
        .statuses
        .except(:draft)
        .map { |key, value| { name: I18n.t("simple_form.options.service.status.#{key}"), id: value } }
  end

  def where_constraint
    { @index.to_sym => value }
  end
end
