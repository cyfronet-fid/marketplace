# frozen_string_literal: true

class Filter::AncestryMultiselect < Filter
  def initialize(params:, title:, field_name:, model:, joining_model:, index:, model_type: nil, search: false)
    super(
      params: params,
      type: :multiselect,
      field_name: field_name,
      title: title,
      model_type: model_type,
      index: index
    )
    @model = model
    @joining_model = joining_model
    @search = search
  end

  def search?
    @search
  end

  private

  def fetch_options
    arranged = @model_type.blank? ? @model.arrange : @model.arrange.select { |e| e.type == @model_type }
    @ancestry_counters = count(arranged)
    create_ancestry_tree(arranged)
  end

  def count(arranged)
    arranged.inject({}) do |counters, (record, children)|
      counters.merge(
        count(children).tap do |children_counters|
          counters[record.id] = @counters[record.id].to_i + (children_counters&.reduce(0) { |p, (_k, v)| p + v }).to_i
        end
      )
    end
  end

  def create_ancestry_tree(arranged)
    arranged
      .map do |record, children|
        {
          name: record.name,
          id: record.id,
          count: @counters[record.id].to_i,
          parent_id: record.ancestry,
          children: create_ancestry_tree(children)
        }
      end
      .sort_by! { |e| [-e[:count], e[:name]] }
  end

  def where_constraint
    { @index.to_sym => ids }
  end

  def relation_column_name
    "#{@model.table_name.singularize}_id"
  end

  def name(val)
    ancestry_name(val, options)&.[](:name)
  end

  def ancestry_name(val, options)
    options.find { |option| val == option[:id].to_s } ||
      options.inject(nil) { |p, option| p || ancestry_name(val, option[:children]) }
  end

  def ids
    @ids ||=
      begin
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
