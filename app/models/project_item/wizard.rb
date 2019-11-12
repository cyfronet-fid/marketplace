# frozen_string_literal: true

class ProjectItem::Wizard
  STEPS = %w(offers information configuration summary)

  def initialize(service)
    @service = service
  end

  def step(step, attrs = {})
    raise InvalidStep unless step.to_s.in?(ProjectItem::Wizard::STEPS)

    "ProjectItem::Wizard::#{step.to_s.camelize}Step"
      .constantize.new(@service, attrs)
  end

  def step_names
    STEPS
  end

  class InvalidStep < StandardError; end

  private

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

      def model_name
        project_item.model_name
      end
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
    end

    class ConfigurationStep < OffersStep
      include ProjectItem::Customization
      include ProjectItem::VoucherValidation

      delegate :created?, to: :project_item

      def visible?
        true
      end

      def error
        "Please correct errors presented below"
      end
    end

    class SummaryStep < ConfigurationStep
      include ProjectItem::ProjectValidation
      delegate :properties?, to: :project_item

      def visible?
        true
      end
    end
end
