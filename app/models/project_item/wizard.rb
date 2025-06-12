# frozen_string_literal: true

class ProjectItem::Wizard
  STEPS = %i[choose_offer information configuration summary].freeze

  def initialize(service)
    @service = service
  end

  def step(step, attrs = {})
    raise InvalidStep unless step.in?(step_names)

    "ProjectItem::Wizard::#{step.to_s.camelize}Step".constantize.new(@service, attrs)
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

  class InvalidStep < StandardError
  end

  class Base
    include ActiveModel::Model
    attr_accessor :project_item, :service

    delegate(*::ProjectItem.attribute_names.map { |a| [a, "#{a}="] }.flatten, to: :project_item)

    delegate :offer, :bundle, :project, :parent, :voucher_id, :request_voucher, to: :project_item

    def initialize(service, project_item_attributes)
      @service = service
      @project_item = ::CustomizableProjectItem.new(project_item_attributes)
    end

    def model_name
      project_item.model_name
    end
  end

  class ChooseOfferStep < Base
    validates :offer, presence: true, unless: :bundle
    validates :bundle, presence: true, unless: :offer

    def visible?
      service.offers.inclusive.size + service.bundles_count > 1
    end

    def error
      "Please select one of the offer or bundle"
    end
  end

  class InformationStep < ChooseOfferStep
    def visible?
      true
    end
  end

  class ConfigurationStep < ChooseOfferStep
    include ProjectItem::Customization
    include ProjectItem::VoucherValidation

    delegate :created?, :bundled_parameters, to: :project_item

    def visible?
      offer.nil? || (bundle.present? && bundle.all_offers&.map(&:parameters)&.any?(&:present?)) ||
        project_item.property_values.count.positive? || voucherable?
    end

    def error
      "Please correct errors presented below"
    end
  end

  class SummaryStep < ConfigurationStep
    include ProjectItem::ProjectValidation
    include ProjectItem::VoucherValidation

    delegate :additional_comment, to: :project_item

    attr_accessor :verified_recaptcha

    def error
      "Please correct errors presented below"
    end

    def visible?
      true
    end
  end
end
