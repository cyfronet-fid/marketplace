# frozen_string_literal: true

class Filter::Provider < Filter::Multiselect
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          category: params[:category],
          field_name: "providers",
          title: "Providers",
          model: ::Provider,
          index: "providers",
          filter_scope: params[:filter_scope])
  end

  private

    def do_call(services)
      services.joins(:service_providers).group("services.id")
          .where("service_providers.provider_id IN (?)", value)
    end
end
