# frozen_string_literal: true

class Filter::TargetUser < Filter::Multiselect
  def initialize(params = {})
    super(
      params: params.fetch(:params, {}),
      field_name: "dedicated_for",
      title: "Dedicated for",
      model: ::TargetUser,
      index: "dedicated_for"
    )
  end
end
