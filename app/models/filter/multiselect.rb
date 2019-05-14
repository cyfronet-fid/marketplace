# frozen_string_literal: true

class Filter::Multiselect < Filter
  def initialize(params:, category:, query:, title:, field_name:)
    super(params: params, field_name: field_name,
          type: :multiselect, title: title)

    @category = category
    @query = query
  end

  protected

    def fetch_options
      if @category.nil?
        query = @query.joins(:services)
      else
        query = @query.joins(:categories).where(categories: { id: @category.id })
      end

      query.group(:id).order(:name).map do |record|
        { name: record.name, id: record.id, count: record.service_count }
      end
    end
end
