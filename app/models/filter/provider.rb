# frozen_string_literal: true

class Filter::Provider < Filter::Multiselect
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          category: params[:category],
          field_name: "providers",
          title: "Providers",
          query: ::Provider.select("providers.name, providers.id, count(service_providers.service_id) as service_count"))
  end

  private

    def do_call(services)
      services.joins(:service_providers).group("services.id")
          .where("service_providers.provider_id IN (?)", value)
    end
end
