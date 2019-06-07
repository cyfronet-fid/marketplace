# frozen_string_literal: true

class Filter::AncestryMultiselect < Filter
  def initialize(params:, title:, field_name:, model:, joining_model:, index:)
    super(params: params, type: :multiselect,
          field_name: field_name, title: title, index: index)
    @model = model
    @joining_model = joining_model
  end

  private

    def fetch_options
      create_ancestry_tree(@model.arrange)
    end

    def create_ancestry_tree(arranged)
      arranged.map do |record, children|
        {
          name: record.name,
          id: record.id,
          count: @counters[record.id] || 0,
          children: create_ancestry_tree(children)
        }
      end.sort_by!{ |e| [-e[:count], e[:name] ] }
    end

    def children_services(arranged)
      arranged.inject(Set.new) do |s, (record, children)|
        s | grouped_services[record.id] | children_services(children)
      end
    end

    def grouped_services
      @grouped_services ||=
        @joining_model.pluck(relation_column_name, :service_id).
          inject(Hash.new { |h, k| h[k] = Set.new }) { |h, (k, v)| h[k] << v; h }
    end

    def where_constraint
      { @index.to_sym => ids }
    end

    def relation_column_name
      "#{@model.table_name.singularize}_id"
    end

    def ids
      @ids ||= begin
        selected = @model.where(id: values)
        grouped = selected.group_by { |record| parent?(record, selected) }
        (
          (grouped[true]&.map(&:id) || []) +
          (grouped[false]&.map { |record| [record.id] + record.descendant_ids } || [])
        ).flatten
      end
    end

    def parent?(record, selected)
      selected.any? { |s| record.parent_of?(s) }
    end
end
