# frozen_string_literal: true

require "uri"

module EoscExploreBannerHelper
  CONFIG = Mp::Application.config_for(:eosc_explore_banner).freeze

  def matching_tags(tags)
    tags = tags.map(&:downcase)
    permitted = CONFIG[:tags]
    permitted.select { |tag| tags.include?(tag.downcase) }
  end

  def eosc_explore_url(tags)
    URI.parse(
      CONFIG[:base_url] + CONFIG[:search_url] +
        ERB::Util.url_encode("(\"#{matching_tags(tags)&.map { |tag| tag.split("::").last }&.join("\" OR \"")}\")")
    )
  end

  def show_banner?(tags)
    matching_tags(tags).present?
  end
end
