# frozen_string_literal: true

class Link::MultimediaUrl < Link
  validate :http_url

  private

  def http_url
    errors.add(:url, :url, value: url) if url.present? && !UrlHelper.url?(url)
  end
end
