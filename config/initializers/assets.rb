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
# and are precompiled like them (views and locales are handled in
# config/application.rb, JavaScript and stylesheets by config/esbuild.config.js
# and config/sass.config.js).
if ENV["CUSTOMIZATION_PATH"].present?
  customization_images = File.join(ENV["CUSTOMIZATION_PATH"], "images")
  Rails.application.config.assets.paths.unshift(customization_images)
  Rails.application.config.assets.precompile +=
    Dir[File.join(customization_images, "**", "*")].select { |file| File.file?(file) }.map do |file|
      file.delete_prefix("#{customization_images}/")
    end
end

Rails.application.config.assets.precompile += %w[trix.css bootstrap.min.js popper.js]
#
# # Precompile additional assets.
# # application.js, application.css, and all non-JS/CSS in the app/assets
# # folder are already added.
# # Rails.application.config.assets.precompile += %w( admin.js admin.css )
