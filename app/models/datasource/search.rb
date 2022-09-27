# frozen_string_literal: true

module Datasource::Search
  extend ActiveSupport::Concern

  included do
    # ELASTICSEARCH
    # scope :search_import working with should_indexe?
    # and define which datasources are indexed in elasticsearch
    searchkick word_middle: %i[datasource_name], highlight: %i[datasource_name]
  end

  # search_data are definition which
  # fields are mapped to elasticsearch
  def search_data
    { datasource_id: id, datasource_name: name }
  end

  private

  def search_scientific_domains_ids
    (scientific_domains.map(&:ancestor_ids) + scientific_domains.map(&:id)).flatten.uniq
  end
end
