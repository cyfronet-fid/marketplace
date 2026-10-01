# frozen_string_literal: true

class Presentable::StatusActionsComponent < ApplicationComponent
  include FormsHelper
  include Turbo::FramesHelper

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

  # whitelabel routes every unpublish/suspend through an unpublish resource
  # (Backoffice::Services::UnpublishesController for services); marketplace
  # and pl send services through drafts.
  def suspend_path
    return polymorphic_path([:backoffice, @object, :unpublish], suspend: true) if Mp::Variant.whitelabel?

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
    return polymorphic_path([:backoffice, @object, :unpublish]) if Mp::Variant.whitelabel?

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
