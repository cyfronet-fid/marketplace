# frozen_string_literal: true

require "uri"

module EoscExploreBannerHelper
  CONFIG = Mp::Application.config_for(:eosc_explore_banner).freeze

  def first_matching_tag(tags)
    tags = tags.map(&:downcase)
    permitted = CONFIG[:tags]
    permitted.select { |tag| tags.include?(tag.downcase) }.first
  end

  def eosc_explore_url(tags)
    URI.parse(CONFIG[:base_url] + CONFIG[:search_url] + ERB::Util.url_encode(first_matching_tag(tags)).gsub("%", "%25"))
  end

  def show_banner?(tags)
    first_matching_tag(tags).present?
  end
end
