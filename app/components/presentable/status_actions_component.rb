# frozen_string_literal: true

class Presentable::StatusActionsComponent < ApplicationComponent
  include FormsHelper
  def initialize(object:, publish: false, unpublish: false, suspend: false, destroy: false)
    super()
    @object = object
    @object_type = object_type
    @publish = publish
    @unpublish = unpublish
    @suspend = suspend
    @destroy = destroy
  end

  def object_type
    @object.class.name.downcase == "datasource" ? "service" : @object.class.name.downcase
  end

  def suspend_path
    case @object
    when Service
      backoffice_service_draft_path(@object, suspend: true)
    when Provider
      backoffice_provider_unpublish_path(@object, suspend: true)
    when Catalogue
      backoffice_catalogue_unpublish_path(@object, suspend: true)
    end
  end

  def unpublish_path
    case @object
    when Service
      backoffice_service_draft_path(@object)
    when Provider
      backoffice_provider_unpublish_path(@object)
    when Catalogue
      backoffice_catalogue_unpublish_path(@object)
    end
  end
end
