# frozen_string_literal: true

module Webpacker::Helper
  def resolve_path_to_image(name)
    # this is a little hack, but Manifest does not expose any other easy way to access hash of compiled
    # resources. This helper should only be included in very specific developer mode, so it should
    # not be an issue
    manifest_data = current_webpacker_instance.manifest.send :data
    if key = manifest_data.keys.find { |k| /media\/.+\/javascript\/.+\/#{name}/.match(k) }
      asset_path(current_webpacker_instance.manifest.lookup!(key))
    else
      path = name.starts_with?("media/images/") ? name : "media/images/#{name}"
      asset_path(current_webpacker_instance.manifest.lookup!(path))
    end
  rescue
    asset_path(current_webpacker_instance.manifest.lookup!(name))
    end
end
