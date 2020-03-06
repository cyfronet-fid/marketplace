# frozen_string_literal: true

module ComparisonsHelper
  def checked?(slug)
    session[:comparison]&.include?(slug)
  end
end
