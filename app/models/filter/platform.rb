# frozen_string_literal: true

class Filter::Platform < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "related_platforms", type: :multiselect,
          title: "Related Infrastructures and platforms")

    @category = params[:category]
  end

  private

    def fetch_options
      query = ::Platform.select("platforms.name, platforms.id, COUNT(services.id) as service_count")

      if @category.nil?
        query = query.joins(:services)
      else
        query = query.joins(:categories).where("categories.id = ?", @category.id)
      end

      query.group("platforms.id")
          .order(:name)
          .map { |provider| [provider.name, provider.id, provider.service_count] }
    end

    def do_call(services)
      services.joins(:service_related_platforms).group("services.id").
          where("service_related_platforms.platform_id IN (?)", value)
    end
end
