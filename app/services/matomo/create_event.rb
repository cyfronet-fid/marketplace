# frozen_string_literal: true

require "net/http"

class Matomo::CreateEvent
  ACTIONS = { add_to_project: "AddToProject", rate: "Rate" }.freeze

  def initialize(project_item, action, value = nil, category = "Service")
    @project_item = project_item
    @action = action
    @category = category
    @value = value
  end

  def call
    sid = @project_item.service.sources&.first&.eid || @project_item.service.slug
    url = Mp::Application.config.matomo_url
    site_id = Mp::Application.config.matomo_site_id
    request = "https:" + url + "matomo.php?e_c=#{@category}&e_a=#{@action}&e_n=#{sid}&idsite=#{site_id}&rec=1"
    request += "&e_v=#{@value}" if @action == ACTIONS[:rate] && @value.present?
    Net::HTTP.get_response(URI(request))
  end
end
