# frozen_string_literal: true

# Breadcrumbs of a deployment: $CUSTOMIZATION_PATH/config/breadcrumbs/**/*.rb
# is loaded after the repository's config/breadcrumbs. Gretel keeps one block
# per crumb name and the last loaded file wins, so a crumb defined there
# replaces the repository's crumb with the same name. Crumbs the deployment
# does not redefine keep coming from the repository.
if ENV["CUSTOMIZATION_PATH"].present?
  Gretel.breadcrumb_paths += [Pathname.new(ENV["CUSTOMIZATION_PATH"]).join("config", "breadcrumbs", "**", "*.rb")]
end
