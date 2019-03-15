# frozen_string_literal: true

class Filter::TargetGroup < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "target_groups", type: :multiselect,
          title: "For")
    @category = params[:category]
  end

  private

    def fetch_options
      @options_target_groups ||= begin
        query = ::TargetGroup.select("target_groups.name, target_groups.id, count(services.id) as service_count")

        if @category.nil?
          query = query.joins(:services)
        else
          query = query.joins(:categories).where("categories.id = ?", @category.id)
        end

        query.group("target_groups.id")
            .order(:name)
            .map { |target_group| [target_group.name, target_group.id, target_group.service_count] }
      end
    end

    def do_call(services)
      services.joins(:service_target_groups).
          where("service_target_groups.target_group_id IN (?)", value)
    end
end
