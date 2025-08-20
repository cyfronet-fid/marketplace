# frozen_string_literal: true

class Recommender::DeployableServiceSerializer < ApplicationSerializer
  attributes :id, :pid, :name, :description, :tagline, :status, :resource_organisation
  attribute :scientific_domains
end
