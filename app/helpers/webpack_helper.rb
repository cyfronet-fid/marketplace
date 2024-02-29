# frozen_string_literal: true

module WebpackHelper
  def self.resolve_path_to_image(name)
    # this is a little hack, but Manifest does not expose any other easy way to access hash of compiled
    # resources. This helper should only be included in very specific developer mode, so it should
    # not be an issue

    manifest_data = webpack_manifest
    key = manifest_data.keys.find { |k| %r{media/images/#{name}}.match(k) }

    return ActionController::Base.helpers.asset_url(webpack_manifest[key]) if key

    path = name.starts_with?("media/images/") ? name : "media/images/#{name}"
    ActionController::Base.helpers.asset_url(webpack_manifest[path])
  rescue StandardError
    ActionController::Base.helpers.asset_url(webpack_manifest[name])
  end

  def self.load_webpack_manifest
    JSON.parse(File.read("public/packs/manifest.json"))
  rescue Errno::ENOENT
    raise "The webpack manifest file does not exist." unless Rails.configuration.assets.compile
  end

  def self.webpack_manifest
    # Always get manifest.json on the fly in development mode
    return load_webpack_manifest if Rails.env.development?

    # Get cached manifest.json if available, else cache the manifest
    Rails.configuration.x.webpack.manifest ||= load_webpack_manifest
  end
end
