# frozen_string_literal: true

class Filter::TargetGroup < Filter::Multiselect
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          category: params[:category],
          field_name: "target_groups",
          title: "Dedicated for",
          query: ::TargetGroup.select("target_groups.name, target_groups.id, count(services.id) as service_count"))
  end

  private

    def do_call(services)
      services.joins(:service_target_groups).
          where("service_target_groups.target_group_id IN (?)", value)
    end
end
