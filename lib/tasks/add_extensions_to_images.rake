# frozen_string_literal: true

require "image_processing/vips"

desc "Add an extension to the images that has lack of them"
task :add_extension_to_images, [:root_url] => :environment do |_, args|
  routes_default_host = Rails.application.routes.default_url_options[:host]
  app_default_host = Mp::Application.default_url_options[:host]

  Rails.application.routes.default_url_options[:host] = args.root_url
  Mp::Application.default_url_options[:host] = args.root_url

  include Rails.application.routes.url_helpers
  include ApplicationHelper

  add_extension_to_images
ensure
  Rails.application.routes.default_url_options[:host] = routes_default_host
  Mp::Application.default_url_options[:host] = app_default_host
end

class LogoNotAvailableError < StandardError
end

def add_extension_to_images
  objects_with_img = Provider.all.to_a.push(*Service.all.to_a).push(*Category.all.to_a).push(*ScientificDomain.all.to_a)
  objects_with_img.each do |object|
    if should_rename(object.logo)
      filename = object.pid.blank? ? "logo_" + to_slug(object.name) : object.pid
      rename_img(object.logo, filename)
    end
  end
end

def rename_img(attachment, filename)
  logo = URI.parse(url_for(attachment)).open(ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
  logo_content_type = logo.content_type
  extension = Rack::Mime::MIME_TYPES.invert[logo_content_type]

  unless %w[.jpg .jpeg .pjpeg .png .gif .tiff].include?(extension)
    img = Vips::Image.new_from_buffer(logo, "")
    logo.rewind

    img = Vips::Image.thumbnail(img, 800, height: 800, size: :down)
    img.write_to_buffer(".png")

    logo = StringIO.new
    logo.write(img)
    logo.rewind
  end
  if logo.present? && logo_content_type.start_with?("image")
    attachment.attach(io: logo, filename: filename + extension, content_type: logo_content_type)
  end
rescue OpenURI::HTTPError, Errno::EHOSTUNREACH, LogoNotAvailableError, SocketError => e
  log "ERROR - there was a problem processing image for #{filename} #{url_for(attachment)}: #{e}"
rescue StandardError => e
  log "ERROR - there was a unexpected problem processing image for #{filename} #{url_for(attachment)}: #{e}"
end

def should_rename(attachment)
  return false if attachment.blank? || attachment.filename.blank?

  has_ext = attachment.filename.to_s.match(/\.(jpg|jpeg|pjpeg|png|gif|tiff")$/)
  attachment.attached? && !has_ext
end

def log(msg)
  Rails.logger.warn msg
end

def to_slug(ret)
  ret.downcase!
  ret.strip!
  ret.gsub!(/['`]/, "")
  ret.gsub!(/\s*@\s*/, " at ")
  ret.gsub!(/\s*&\s*/, " and ")
  ret.gsub!(/\s*[^A-Za-z0-9.-]\s*/, "-")
  ret.gsub!(/_+/, "_")
  ret.gsub!(/\A[_.]+|[_.]+\z/, "")
  ret.gsub!(/-+/, "-")
  ret.gsub!(/-$/, "")
  ret
end
