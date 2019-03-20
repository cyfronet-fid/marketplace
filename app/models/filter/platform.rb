# frozen_string_literal: true

class Filter::Platform < Filter::Multiselect
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          category: params[:category],
          field_name: "related_platforms",
          title: "Related Infrastructures and platforms",
          query: ::Platform.select("platforms.name, platforms.id, COUNT(services.id) as service_count"))
  end

  private

    def do_call(services)
      services.joins(:service_related_platforms).group("services.id").
          where("service_related_platforms.platform_id IN (?)", value)
    end
end
