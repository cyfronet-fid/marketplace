# frozen_string_literal: true

# Parsed TOSCA template of a deployable service. ADM fetches the template itself,
# so only the declared inputs and outputs are read here.
class DeployableService::ToscaTemplate
  def self.fetch(url)
    new(DeployableService::FetchTemplate.call(url))
  end

  def initialize(content)
    parsed = YAML.safe_load(content)
    topology = parsed["topology_template"] if parsed.is_a?(Hash)
    @topology = topology.is_a?(Hash) ? topology : {}
  end

  def inputs
    section("inputs")
  end

  def output_names
    section("outputs").keys
  end

  private

  def section(name)
    value = @topology[name]
    value.is_a?(Hash) ? value : {}
  end
end
