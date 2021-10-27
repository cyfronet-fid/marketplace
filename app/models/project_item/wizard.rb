# frozen_string_literal: true

class ProjectItem::Wizard
  STEPS = %i[offers information configuration summary].freeze

  def initialize(service)
    @service = service
  end

  def step(step, attrs = {})
    raise InvalidStep unless step.in?(step_names)

    "ProjectItem::Wizard::#{step.to_s.camelize}Step"
      .constantize.new(@service, attrs)
  end

  def next_step_key(step)
    index = step_names.index(step)
    step_names[index + 1] if index < step_names.length - 1
  end

  def prev_step_key(step)
    index = step_names.index(step)
    step_names[index - 1] if index.positive?
  end

  def step_names
    STEPS
  end

  class InvalidStep < StandardError; end

  class Base
    include ActiveModel::Model
    attr_accessor :project_item, :service

    delegate(*::ProjectItem.attribute_names.map { |a| [a, "#{a}="] }.flatten,
             to: :project_item)

    delegate :offer, :project, to: :project_item

    def initialize(service, project_item_attributes)
      @service = service
      @project_item = ::ProjectItem.new(project_item_attributes)
    end

    delegate :model_name, to: :project_item
  end

  class OffersStep < Base
    validates :offer, presence: true

    def visible?
      service.offers_count > 1
    end

    def error
      "Please select one of the offer"
    end
  end

  class InformationStep < OffersStep
    def visible?
      true
    end
  end

  class ConfigurationStep < OffersStep
    include ProjectItem::Customization
    include ProjectItem::VoucherValidation

    delegate :created?, to: :project_item

    def visible?
      offer.nil? || offer.bundle? || project_item.property_values.count.positive? || voucherable?
    end

    def error
      "Please correct errors presented below"
    end
  end

  class SummaryStep < ConfigurationStep
    include ProjectItem::ProjectValidation
    delegate :properties?, to: :project_item

    attr_accessor :additional_comment, :verified_recaptcha

    def error
      "Please correct errors presented below"
    end

    def visible?
      true
    end
  end
end
