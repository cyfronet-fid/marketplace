# frozen_string_literal: true

class Api::V1::UserSerializer < ActiveModel::Serializer
  attributes :uid, :roles, :providers, :catalogues

  def roles
    object.roles.map(&:name)
  end

  def providers
    object.providers.map { |p| Api::V1::ProviderSerializer.new(p).as_json }
  end

  def catalogues
    object.catalogues.map { |c| Api::V1::CatalogueSerializer.new(c).as_json }
  end
end
