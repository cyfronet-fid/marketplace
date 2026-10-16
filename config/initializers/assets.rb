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

# Images are precompiled by logical path through the load path, not by
# `link_tree ../images` in manifest.js, which links files by location. A
# same-named image under $CUSTOMIZATION_PATH/images then resolves first and
# replaces the repository image. Linked by location, the two files would
# share one output path, which Sprockets refuses (DoubleLinkError).
# (Views and locales are handled in config/application.rb, JavaScript and
# stylesheets by config/esbuild.config.js and config/sass.config.js.)
image_names =
  lambda do |directory|
    Dir[File.join(directory, "**", "*")]
      .select { |file| File.file?(file) && !File.basename(file).start_with?(".") }
      .map { |file| file.delete_prefix("#{directory}/") }
  end

Rails.application.config.assets.precompile += image_names.call(Rails.root.join("app/assets/images").to_s)

if ENV["CUSTOMIZATION_PATH"].present?
  customization_images = File.join(ENV["CUSTOMIZATION_PATH"], "images")
  # Prepended to the Sprockets environment, not to config.assets.paths:
  # sprockets-rails puts app/assets/* in front of that list after this file
  # ran (its append_assets_path initializer).
  Rails.application.config.assets.configure { |env| env.prepend_path(customization_images) }
  Rails.application.config.assets.precompile |= image_names.call(customization_images)
end

Rails.application.config.assets.precompile += %w[trix.css bootstrap.min.js popper.js]
#
# # Precompile additional assets.
# # application.js, application.css, and all non-JS/CSS in the app/assets
# # folder are already added.
# # Rails.application.config.assets.precompile += %w( admin.js admin.css )
