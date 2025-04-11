# frozen_string_literal: true

module Recommendation::Followable
  extend ActiveSupport::Concern
  include ValidationHelper

  included { before_action :set_follow_context }

  private

  def set_follow_context
    # otherwise the chain of SARS elements will be broken, as AJAX request do not reload whole page
    return if request.xhr?

    # Set unique client id per device per system
    client_uid = cookies[:client_uid]
    if client_uid.nil? || !validate_uuid_format(client_uid)
      cookies[:client_uid] = { value: SecureRandom.uuid, expires: 1.week.from_now }
    end

    @recommendation_previous = cookies.fetch(:source, "{}")
    @recommendation_source_id = cookies.fetch(:targetId, "")
    @last_page_id = cookies[:lastPageId]
  end
end
