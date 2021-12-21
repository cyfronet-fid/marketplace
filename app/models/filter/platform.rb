# frozen_string_literal: true

class Filter::Platform < Filter::Multiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "related_platforms",
      title: "Related Infrastructures and platforms",
      model: ::Platform,
      index: "platforms",
      search: true
    )
  end
end
