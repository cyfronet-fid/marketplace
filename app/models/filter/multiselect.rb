# frozen_string_literal: true

class Filter::Multiselect < Filter
  def initialize(params:, category:, title:, field_name:, model:, index:, filter_scope:)
    super(params: params, field_name: field_name,
          type: :multiselect, title: title)
    @model = model
    @index = index
    @category = category
    @filter_scope = filter_scope
  end

  protected

    def fetch_options
      counters = @filter_scope.aggregations[@index][@index]["buckets"].
          inject({}){ |h, e| h[e["key"]]=e["doc_count"]; h}
      entities = @model.order(:name).find(counters.keys)
      entities.map() {|p| {name: p.name, id: p.id, count: counters[p.id]}}
    end
end
