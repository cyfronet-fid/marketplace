# frozen_string_literal: true

class Api::V1::Search::ServiceSerializer < ApplicationSerializer
  include ImageHelper

  attribute :marketplace_locations, key: :research_activities
  attributes :pid,
             :name,
             :slug,
             :tagline,
             :description,
             :rating,
             :score,
             :path,
             :logo,
             :scientific_domains,
             :target_users,
             :platforms,
             :resource_organisation,
             :providers,
             :source_node_url

  def score
    instance_options[:score]
  end

  def path
    Rails.application.routes.url_helpers.service_url(object)
  end

  def logo
    object.logo.attached? ? Rails.application.routes.url_helpers.service_logo_url(object) : nil
  end

  def source_node_url
    Rails.application.routes.url_helpers.root_url
  end

  def resource_organisation
    return nil unless object.resource_organisation
    Api::V1::Search::ProviderSerializer.new(object.resource_organisation).as_json
  end

  def providers
    object.providers.map { |p| Api::V1::Search::ProviderSerializer.new(p).as_json }
  end

  %i[scientific_domains target_users platforms marketplace_locations].each do |relation|
    define_method(relation) do
      object.public_send(relation).map { |item| Api::V1::Search::FilterSerializer.new(item).as_json }
    end
  end

  private

  def pid
    object.pid || object.sources&.first&.eid
  end

  def tags
    object.tag_list
  end
end
