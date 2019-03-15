# frozen_string_literal: true

class Filter::Provider < Filter
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          field_name: "providers", type: :multiselect,
          title: "Providers")

    @category = params[:category]
  end

  private

    def fetch_options
      query = ::Provider.select("providers.name, providers.id, count(service_providers.service_id) as service_count")

      if @category.nil?
        query = query.joins(:services)
      else
        query = query.joins(:categories).where("categories.id = ?", @category.id)
      end

      query.group("providers.id")
          .order(:name)
          .map { |provider| [provider.name, provider.id, provider.service_count] }
    end

    def do_call(services)
      services.joins(:service_providers).group("services.id")
          .where("service_providers.provider_id IN (?)", value)
    end
end
