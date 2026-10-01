# frozen_string_literal: true

module Checkin
  class Config
    def self.vo_group_name
      ENV.fetch("VO_GROUP_NAME", nil)
    end

    def self.become_vo_member_url
      ENV.fetch("BECOME_VO_MEMBER_URL", nil)
    end
  end
end
