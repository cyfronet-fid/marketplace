# frozen_string_literal: true

# The ESS JSON of a collection of records, each serialized by the given
# serializer. Statistics the serializer would otherwise query once per record
# are counted once for the whole collection: the Orders of Services and
# Datasources (Statistics::OrderCounts), sent as usage_counts_downloads.
class Ess::SerializeCollection < ApplicationService
  def initialize(records, serializer)
    super()
    @records = records
    @serializer = serializer
  end

  def call
    options = serializer_options
    @records.map { |record| @serializer.new(record, options).as_json }
  end

  private

  # Ess::DatasourceSerializer inherits usage_counts_downloads from it.
  def serializer_options
    @serializer <= Ess::ServiceSerializer ? { order_counts: Statistics::OrderCounts.call(@records) } : {}
  end
end
