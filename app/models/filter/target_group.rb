# frozen_string_literal: true

class Filter::TargetGroup < Filter::Multiselect
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "target_groups",
          title: "Dedicated for",
          model: ::TargetGroup,
          index: "target_groups")
  end
end
