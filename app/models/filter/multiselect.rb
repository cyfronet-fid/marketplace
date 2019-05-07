# frozen_string_literal: true

class Filter::Multiselect < Filter

  def initialize(params:, title:, field_name:, model:, index:)
    super(params: params, field_name: field_name,
          type: :multiselect, title: title, index: index)
    @model = model
  end

  protected

    def fetch_options
      counters = @filter_scope.aggregations[@index][@index]["buckets"].
          inject({}){ |h, e| h[e["key"]] = e["doc_count"]; h}
      @model.distinct
          .map { |e| {name: e.name, id: e.id, count: counters[e.id] || 0} }
          .sort_by!{ |e| [-e[:count], e[:name] ] }
    end

    def where_constraint
      { @index.to_sym => values }
    end

end
