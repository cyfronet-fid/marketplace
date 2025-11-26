# frozen_string_literal: true

module ResearchProductsHelper
  def download_research_product_data
    base_url = Mp::Application.config.search_service_base_url
    endpoint = Mp::Application.config.search_service_research_product_endpoint
    path = "#{params[:resource_type]}/#{CGI.escape(params[:resource_id])}"
    faraday = Faraday.new { |config| config.response :raise_error }
    response = faraday.get(base_url + endpoint + path)
    if response.status == 200
      body = JSON.parse(response.body)
      if body["type"] == @research_product&.resource_type
        @research_product.update(body)
      else
        @research_product.assign_attributes(body)
        @research_product.save!
      end
    end
  rescue StandardError => e
    flash[:alert] = "Due to a poor metadata of the research product it cannot be added to the User Space. " +
      "Server response: #{e}"
  end
end
