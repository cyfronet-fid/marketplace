# frozen_string_literal: true

class Filter::TargetUser < Filter::Multiselect
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "target_users",
          title: "Dedicated for",
          model: ::TargetUser,
          index: "target_users")
  end
end
