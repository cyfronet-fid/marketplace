# frozen_string_literal: true

module ProjectItem::Wizard
  class Base
    include ActiveModel::Model
    attr_accessor :project_item

    delegate(*::ProjectItem.attribute_names.map { |a| [a, "#{a}="] }.flatten,
             to: :project_item)

    delegate :offer, :project, to: :project_item

    def initialize(project_item_attributes)
      @project_item = ::ProjectItem.new(project_item_attributes)
    end

    def to_model
      project_item
    end
  end

  class OfferSelectionStep < Base
    validates :offer, presence: true

    def error
      "Please select one of the offer"
    end
  end

  class ConfigurationStep < OfferSelectionStep
    # include ProjectItem::Customization

    validates :project, presence: true
  end

  class SummaryStep < ConfigurationStep
  end
end
