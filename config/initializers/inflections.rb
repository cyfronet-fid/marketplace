# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "OMS"
  inflect.acronym "OMSes"
  inflect.irregular "oms", "omses"
  inflect.irregular "area_of_activity", "areas_of_activity"
  inflect.irregular "AreaOfActivity", "AreasOfActivity"
  inflect.irregular "Area of Activity", "Areas of Activity"
  inflect.irregular "capability_of_goals", "capabilities_of_goals"
  inflect.irregular "CapabilityOfGoals", "CapabilitiesOfGoals"
  inflect.irregular "Capability of Goals", "Capabilities of Goals"
  inflect.irregular "bundle_capability_of_goal", "bundle_capabilities_of_goal"
  inflect.irregular "BundleCapabilityOfGoal", "BundleCapabilitiesOfGoal"
  inflect.irregular "Bundle Capability of Goal", "Bundle Capabilities of Goal"
end
