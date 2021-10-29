# frozen_string_literal: true

module Service::Comparison
  extend ActiveSupport::Concern

  included do
    before_action :init_comparison_variables, only: %i[index show]
  end

  def init_comparison_variables
    @compare_services = Service.where(slug: session[:comparison])
    @comparison_enabled = (session[:comparison]&.size || 0) > 2
  end
end
