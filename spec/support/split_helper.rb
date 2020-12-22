# frozen_string_literal: true

module SplitHelper
  def use_ab_test(alternatives_by_experiment)
    allow_any_instance_of(Split::Helper).to receive(:ab_test) do |_receiver, experiment|
      alternatives_by_experiment.fetch(experiment) { |key| raise "Unknown experiment '#{key}'" }
    end
  end
end

RSpec.configure do |config|
  config.include SplitHelper
end
