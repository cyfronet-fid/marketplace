# frozen_string_literal: true

#
# require "#{Rails.root}/lib/core_extensions/webpack/helper.rb" if ENV["CUSTOMIZATION_PATH"].present?
# # Be sure to restart your server when you modify this file.
#
# # Version of your assets, change this if you want to expire all your assets.
# Rails.application.config.assets.version = "1.0"
#
# # Add additional assets to the asset load path.
# # Rails.application.config.assets.paths << Emoji.images_path
# # Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join("node_modules")

# Images under $CUSTOMIZATION_PATH/images override same-named repository images
# (views and locales are handled in config/application.rb, stylesheets by
# CSS_ENTRY in package.json's build:css).
if ENV["CUSTOMIZATION_PATH"].present?
  Rails.application.config.assets.paths.unshift(File.join(ENV["CUSTOMIZATION_PATH"], "images"))
end

Rails.application.config.assets.precompile += %w[trix.css bootstrap.min.js popper.js]
#
# # Precompile additional assets.
# # application.js, application.css, and all non-JS/CSS in the app/assets
# # folder are already added.
# # Rails.application.config.assets.precompile += %w( admin.js admin.css )
