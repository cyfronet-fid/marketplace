# frozen_string_literal: true

class Filter::Provider < Filter::Multiselect
  def initialize(params = {})
    super(params: params.fetch(:params, {}),
          category: params[:category],
          field_name: "providers",
          title: "Providers",
          query: ::Provider.select("providers.name, providers.id, count(service_providers.service_id) as service_count"))
    @filter_scope = params[:filter_scope]
  end

  private

    # def fetch_options
    #   acc = {}
    #   @filter_scope.each() do |service|
    #     service.providers.each do |provider|
    #       if acc[provider.id] == nil
    #         acc[provider.id] =  { name: provider.name, id: provider.id, count: 0 }
    #       end
    #       acc[provider.id][:count] += 1
    #     end
    #   end
    #   acc.values.sort_by{ |provider| provider[:name] }
    # end

    def fetch_options
      counters = @filter_scope.aggregations["providers"]["providers"]["buckets"].
          inject({}){ |h, e| h[e["key"]]=e["doc_count"]; h}
      providers = ::Provider.order(:name).find(counters.keys)
      providers.map() {|p| {name: p.name, id: p.id, count: counters[p.id]}}
    end

    def do_call(services)
      services.joins(:service_providers).group("services.id")
          .where("service_providers.provider_id IN (?)", value)
    end
end
