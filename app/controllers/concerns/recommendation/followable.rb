# frozen_string_literal: true

module Recommendation::Followable
  extend ActiveSupport::Concern

  included do
    before_action :set_follow_context
  end

  private
    def set_follow_context
      # otherwise the chain of SARS elements will be broken, as AJAX request do not reload whole page
      if request.xhr?
        return
      end

      # Set unique client id per device per system
      if cookies[:client_uid].nil?
        cookies.permanent[:client_uid] = SecureRandom.uuid
      end

      @recommendation_previous = cookies[:source]
      @recommendation_source_id = cookies[:targetId]
      @last_page_id = cookies[:lastPageId]
    end
end
