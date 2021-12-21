# frozen_string_literal: true

class Filter::BackofficeProvider < Filter::Multiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "providers",
      title: "Providers",
      model: ::Provider,
      index: "providers",
      search: true
    )
  end
end
