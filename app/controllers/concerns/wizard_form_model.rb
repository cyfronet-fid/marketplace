# frozen_string_literal: true

module WizardFormModel
  extend ActiveSupport::Concern

  included do
    attr_writer :current_step

    def current_step
      @current_step || steps.first
    end

    def next_step
      self.current_step = steps[steps.index(current_step) + 1]
    end

    def previous_step
      self.current_step = steps[steps.index(current_step) - 1]
    end

    def go_to_step(step)
      raise "step unknown" unless steps.include?(step)
      self.current_step = step
    end

    def required_for_step?(step)
      # All fields are required if no form step is present
      return true if current_step.nil? || step.nil?
      step == current_step
    end

    def all_valid?
      steps.all? do |step|
        self.current_step = step
        valid?
      end
    end

    def steps
      raise "Should be implemented in descendent class"
    end
  end
end
